#!/usr/bin/env python3
"""Assemble reviewed MDP inputs into the existing mochiOS filesystem/boot layout.

This consumer never calls Cargo, a compiler, a producer pipeline or a downloader.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import struct
import subprocess
import sys
import tarfile
import tomllib


class Error(Exception):
    """An invalid or incomplete composition; never a successful image build."""


def check(condition, message):
    """Reject invalid composition metadata before generating trust records."""
    if not condition:raise Error(message)


def digest(path):
    """Hash an artifact or payload with bounded memory."""
    with path.open('rb') as stream:return hashlib.file_digest(stream,'sha256').hexdigest()


def toml_text(data):
    """Serialize package tables without dropping nested capability/dependency declarations."""
    lines=[]
    def table(mapping,path=(),header=None):
        if header:lines.append(header)
        children=[]
        for key,value in mapping.items():
            if isinstance(value,dict) or isinstance(value,list) and value and isinstance(value[0],dict):
                children.append((key,value))
            else:lines.append(json.dumps(key)+' = '+json.dumps(value,allow_nan=False))
        for key,value in children:
            child=(*path,key);name='.'.join(json.dumps(p) for p in child)
            for item in value if isinstance(value,list) else [value]:
                lines.append('');table(item,child,'[['+name+']]' if isinstance(value,list) else '['+name+']')
    table(data)
    return '\n'.join(lines)+'\n'


def relative(value):
    """Limit all product metadata paths to canonical relative POSIX paths."""
    check(isinstance(value,str) and value and '\\' not in value and '\x00' not in value,'invalid product path')
    check(not PurePosixPath(value).is_absolute() and all(p not in ('','.','..') for p in value.split('/')),'product path escapes output')
    return value


def copy(source,target,mode=None):
    """Copy actual verified inputs, rejecting collisions with different content."""
    target.parent.mkdir(parents=True,exist_ok=True)
    check(not target.is_symlink(),'symlink in image output')
    if target.exists():
        check(target.is_file() and digest(target)==digest(source),f'image placement collision: {target}')
    else:
        try:
            check(mode is None or source.stat().st_mode & 0o777 == mode,'copy required for mode normalization')
            os.link(source,target)
        except (OSError,Error):shutil.copy2(source,target)
    if mode is not None and target.stat().st_mode & 0o777 != mode:target.chmod(mode)


def artifact_tree(root, lock_path, areas=None):
    """Verify locked artifacts and cache only a fully verified composed tree."""
    sys.path.insert(0,str(root/'tools/mdp/src'))
    from mdp.cli import assemble,verify
    raw=lock_path.read_bytes();lock=json.loads(raw)
    check(lock.get('format')==1 and lock.get('target')=='x86_64-mochios' and lock.get('abi')=='mochios-1','unsupported OS composition target/ABI')
    areas=set(areas) if areas is not None else {'system','data','boot','initfs','host-tools','applications','manifests','metadata','symbols'}
    selected=root/'out/mdp/assemblies'/(hashlib.sha256(raw+json.dumps(sorted(areas)).encode()).hexdigest()+'-image')
    manifests=[]
    policy=tomllib.loads((root/'build/mdp/policy.toml').read_text())
    names=set();files={}
    for artifact in lock['artifacts']:
        source=lock_path.parent/relative(artifact['path'])
        check(source.resolve().is_relative_to(lock_path.parent.resolve()),'artifact source escapes composition')
        check(digest(source)==artifact['sha256'],f'changed MDP: {source}; rebuild and review the assembly lock')
        manifest=verify(source)
        identity=manifest['package'];name=identity['name']
        check(name not in names and identity==artifact['package'],'duplicate or changed MDP package')
        names.add(name)
        check(identity.get('profile_sha256')==digest(root/'.config'),'MDP was built for a different .config')
        check(identity.get('version_sha256')==digest(root/'version.toml'),'MDP was built for a different OS version')
        rules=policy.get('producers',{}).get(name,policy.get('application') if name.startswith('app-') else None)
        check(rules is not None,f'producer is not allowed in this product: {name}')
        for file in manifest['files']:
            area=file['area'];destination=file['destination']
            check(area in rules,f'{name} may not export area {area}')
            check(any(prefix=='' or destination==prefix or destination.startswith(prefix.rstrip('/')+'/') for prefix in rules[area]),f'{name} may not place {area}/{destination}')
            key=area+'/'+destination
            check(key not in files,'duplicate composition file')
            files[key]=(name,file)
        manifests.append(manifest)
    if not selected.exists():assemble(lock_path,selected,areas)
    tree=selected/'tree'
    # Never trust an old staging directory merely because its receipt exists.
    actual={p.relative_to(tree).as_posix() for p in tree.rglob('*') if p.is_file() or p.is_symlink()}
    expected={key for key in files if key.split('/',1)[0] in areas}
    check(actual==expected,'composed tree has missing or unexpected files')
    for key,(owner,file) in files.items():
        if file['area'] not in areas:continue
        path=tree/key
        if file.get('type')=='symlink':
            check(path.is_symlink() and os.readlink(path)==file['target']
                  and path.resolve().is_relative_to(tree/file['area']),'composed alias changed or escaped')
        else:check(not path.is_symlink() and path.stat().st_size==file['size'] and digest(path)==file['sha256'],'composed payload changed')
    return tree,manifests,files


def extract_application(package, destination):
    """Validate an unsigned MPKG's exact regular-file inventory before unpacking."""
    with package.open('rb') as stream:
        header=stream.read(32)
        check(len(header)==32 and header[:12]==b'MPKG\x01\0\0\0\x20\0\0\0' and header[20:]==b'\0'*12,'expected unsigned MPKG v1')
        check(struct.unpack_from('<Q',header,12)[0]==package.stat().st_size-32,'MPKG expanded size mismatch')
        with tarfile.open(fileobj=stream,mode='r|') as archive:
            first=archive.next()
            check(first is not None and first.name=='manifest.toml' and first.isfile() and first.size<=1024*1024,'invalid MPKG manifest')
            text=archive.extractfile(first).read()
            manifest=tomllib.loads(text.decode())
            check(manifest.get('format')==1 and manifest.get('package',{}).get('kind')=='application','not an application MPKG')
            check(manifest['package'].get('architecture')=='x86_64' and manifest['package'].get('abi')=='mochios-1','MPKG target mismatch')
            records={};ids=set()
            for file in manifest.get('file',[]):
                check(file['path'].startswith('$/'),'application file must be bundle-relative')
                name=relative(file['path'][2:])
                check(name!='manifest.toml','application payload cannot replace its image manifest')
                check(name not in records and file['id'] not in ids,'duplicate MPKG file or ID')
                check(file['mode'] in ('0644','0755') and type(file['size']) is int and file['size']>=0,'invalid MPKG mode or size')
                check(re.fullmatch(r'sha256:[0-9a-f]{64}',file['digest']) is not None,'invalid MPKG digest')
                records[name]=file;ids.add(file['id'])
            check(records and manifest['application']['entry']=='entry.elf','missing native application entry')
            seen=set()
            while (member := archive.next()) is not None:
                check(member.isfile() and not member.issparse() and member.name.startswith('payload/bundle/'),'unexpected MPKG member')
                name=relative(member.name.removeprefix('payload/bundle/'))
                check(name in records and name not in seen,'undeclared or duplicate MPKG member')
                file=records[name]
                check(member.size==file['size'],'MPKG payload size mismatch')
                target=destination/name;target.parent.mkdir(parents=True,exist_ok=True)
                hasher=hashlib.sha256()
                with archive.extractfile(member) as source,target.open('xb') as output:
                    while chunk:=source.read(1024*1024):hasher.update(chunk);output.write(chunk)
                check('sha256:'+hasher.hexdigest()==file['digest'],'MPKG payload hash mismatch')
                target.chmod(int(file['mode'],8));seen.add(name)
                if name=='entry.elf':
                    with target.open('rb') as entry:elf=entry.read(64)
                    check(len(elf)==64 and elf[:6]==b'\x7fELF\x02\x01' and struct.unpack_from('<HH',elf,16)==(2,62),'application entry is not native x86-64 ELF')
            check(seen==set(records),'missing MPKG payload files')
            (destination/'manifest.toml').write_bytes(text)
            return manifest


def skeleton(root,stage,variant,config):
    """Create the existing product's System/Data layout and local account defaults."""
    paths=['bin','applications','libraries/applications','libraries/fonts','home/root','tmp',
           'var/config/applications/org.mochios.edit/users','var/config/workspace','var/log/services',
           'var/lib/accounts','var/lib/keychain','var/lib/certificate','var/lib/diagnostics','var/lib/packages','var/lib/security',
           'system/applications','system/bin','system/libraries','system/packages','system/services']
    for path in paths:(stage/path).mkdir(parents=True,exist_ok=True)
    for path in ['var/lib/keychain','var/lib/diagnostics']:(stage/path).chmod(0o700)
    for path in ['tmp','var/config/applications/org.mochios.edit/users','var/config/workspace']:(stage/path).chmod(0o1777)
    for category in ['account','appearance','diagnostics','general','input','network','security']:
        path=stage/'var/config'/category;path.mkdir(exist_ok=True);path.chmod(0o755 if category=='account' else 0o777)
    shutil.copytree(root/'resources/system',stage/'system',dirs_exist_ok=True)
    shutil.copytree(root/'resources/libraries',stage/'system/libraries',dirs_exist_ok=True)
    shutil.copyfile(root/'resources/system/users/users.db',stage/'var/lib/accounts/users.db')
    (stage/'var/lib/accounts/users.db').chmod(0o600)
    shutil.rmtree(stage/'system/users',ignore_errors=True)
    if variant=='system':(stage/'system/.installed').write_text('format=1\n')
    for user in ['root']+(['testuser'] if config.get('DEVELOPMENT_DEFAULT_ACCOUNT')=='y' else []):
        home=stage/'home'/user;home.mkdir(parents=True,exist_ok=True);home.chmod(0o700)
        for name in ['Desktop','Documents','Downloads','Movies','Music','Pictures']:
            (home/name).mkdir(exist_ok=True);(home/name).chmod(0o700)
    if config.get('DEVELOPMENT_DEFAULT_ACCOUNT')=='y':
        shutil.copyfile(root/'scripts/mmake/development-users.db',stage/'var/lib/accounts/users.db')
        (stage/'var/lib/accounts/users.db').chmod(0o600)
        (stage/'var/config/account/settings.conf').write_text('auto_login=true\nauto_login_user=testuser\n')
        ownership=['home/testuser']+['home/testuser/'+p.name for p in (stage/'home/testuser').iterdir()]
        (stage/'.mochios-ownership').write_text(''.join(path+' 1000 1000\n' for path in ownership))


def bind(msign,source,stage,directory,maps=(),exclude=()):
    """Retain the existing authority path: bind actual files and make a built-in record."""
    directory=relative(directory)
    text=source.read_text()
    check('"window.create"' not in text or '"ipc.server"' in text,'window package cannot receive events without ipc.server')
    output=stage/'system/packages'/directory
    check(not output.exists(),'duplicate built-in package directory')
    output.mkdir(parents=True)
    args=[str(msign),'package','bind-built-in',str(source),'--rootfs',str(stage),'--output',str(output/'manifest.toml')]
    for mapping in maps:args+=['--map-path',mapping]
    for binary in exclude:args+=['--exclude-binary',binary]
    subprocess.run(args,check=True)
    subprocess.run([str(msign),'package','built-in-record',str(output/'manifest.toml'),'--output',str(output/'verification.bin')],check=True)
    (output/'verification.bin').chmod(0o644)


def stage(root,lock,variant):
    """Place verified areas, select product apps, then produce real built-in trust records."""
    config={}
    for line in (root/'.config').read_text().splitlines():
        if line and not line.startswith('#') and '=' in line:
            key,value=line.split('=',1);config[key]=value.strip('"')
    required={'kernel','boot','services','drivers','cexts','runtime','std-demo','fonts','msh','coreutils','devkit-host','image-data','system-components'}
    if config.get('USER_INSTALL_DEVELOPER_TOOLS')=='y':required.add('devkit-native')
    declared={a['package']['name'] for a in json.loads(lock.read_text())['artifacts']}
    check(required<=declared,'composition is missing required producers: '+', '.join(sorted(required-declared))+'; run mdp workspace build')
    tree,manifests,files=artifact_tree(root,lock)
    names={m['package']['name'] for m in manifests}
    check(required<=names,'composition is missing required producers: '+', '.join(sorted(required-names)))
    base=root/'out/mmake'
    work=base if variant=='system' else base/'installer'
    pending=work/'image/rootfs.new'
    if pending.exists():shutil.rmtree(pending)
    pending.mkdir(parents=True)
    skeleton(root,pending,variant,config)
    for key in sorted(files):
        area,destination=key.split('/',1)
        if area not in ('system','data'):continue
        target=pending/('system/'+destination if area=='system' else destination)
        record=files[key][1]
        if record.get('type')=='symlink':
            check(not os.path.lexists(target),'image alias placement collision')
            target.parent.mkdir(parents=True,exist_ok=True);target.symlink_to(record['target'])
        else:copy(tree/key,target,record['mode'])
    initfs=work/'image/mdp-initfs'
    if initfs.exists():shutil.rmtree(initfs)
    initfs.mkdir(parents=True)
    for key in sorted(files):
        if key.startswith('initfs/'):
            copy(tree/key,initfs/key.removeprefix('initfs/'),files[key][1]['mode'])
    allowed={'init','config','disk.cext'}
    check({p.name for p in initfs.iterdir()}<=allowed and (initfs/'init').is_file(),'initfs may contain only core, boot configuration and the required disk cext')
    msign=tree/'host-tools/msign'
    bindings=[];applications={}
    for manifest in manifests:
        name=manifest['package']['name'];metadata=tree/'metadata'/(name+'.json')
        if not metadata.exists():continue
        check(files['metadata/'+name+'.json'][0]==name,'metadata owner mismatch')
        info=json.loads(metadata.read_text())
        if 'application' in info:
            app=info['application'];source=relative(app['source']);package=relative(app['mpkg'])
            check(files.get('applications/'+package,(None,))[0]==name,'application package owner mismatch')
            check(source not in applications,'duplicate application producer')
            applications[source]=tree/'applications'/package
        entries=info.get('builtins',[])
        if info.get('component_catalog'):
            component=tree/'manifests/components.json'
            check(files['manifests/components.json'][0]==name,'component catalog owner mismatch')
            entries+=json.loads(component.read_text())['builtins']
        for entry in entries:
            if any(config.get(k)!=v for k,v in entry.get('when',{}).items()):continue
            source=relative(entry['manifest'])
            check(files.get('manifests/'+source,(None,))[0]==name,'built-in manifest owner mismatch')
            excludes=[]
            if entry.get('coreutils'):
                excludes=['/bin/test_app']
                if config.get('KERNEL_PERFORMANCE_INSTRUMENTATION')!='y':excludes+=['/bin/mperf']
                if config.get('USER_BUILD_SELFTESTS')!='y':excludes+=['/bin/selftest-ext2-write','/bin/selftest-system-layout']
            bindings.append((tree/'manifests'/source,entry['directory'],entry.get('maps',[]),excludes))
    catalog=tomllib.loads((root/'build/application-sets.toml').read_text())
    selected=catalog['system']+(catalog['installer'] if variant=='installer' else [])
    for app in selected:
        check(app['source'] in applications,'missing application MDP: '+app['source'])
        destination=pending/'system/applications'/app['bundle']
        destination.mkdir()
        manifest=extract_application(applications[app['source']],destination)
        check(len(manifest.get('binary',[]))==1,'built-in application must declare one entry executable')
        binary=manifest['binary'][0]
        binding=next((f for f in manifest['file'] if f['id']==binary.get('file')),None)
        check(binding is not None and binding['path']=='$/entry.elf','application entry is not bound to its measured file')
        prefix='/system/applications/'+app['bundle']
        for record in manifest['file']:record['path']=prefix+'/'+relative(record['path'][2:])
        binary['path']=prefix+'/entry.elf'
        # Product policy selects built-ins; the producer cannot grant itself trust.
        manifest['package']['provenance']='built-in'
        (destination/'manifest.toml').write_text(toml_text(manifest))
        bindings.append((destination/'manifest.toml',app['package'],[],[]))
    for source,directory,maps,exclude in bindings:bind(msign,source,pending,directory,maps,exclude)
    (pending/'.ready').touch()
    destination=work/'image/rootfs'
    if destination.exists():shutil.rmtree(destination)
    pending.rename(destination)
    # Compatibility paths are image-generator inputs only, never compilation outputs.
    components=base/'components';components.mkdir(exist_ok=True)
    for name,source in [('kernel.elf',tree/'boot/system/kernel.elf'),('kernel.meta',tree/'boot/system/kernel.meta'),
                        ('kernel.debug',tree/'symbols/kernel.debug'),('BOOTX64.EFI',tree/'boot/EFI/BOOT/BOOTX64.EFI')]:
        shutil.copy2(source,components/name)
    for name in ("boot-selection-seed", "boot-selection-confirm-test", "boot-selection-gpt-probe", "system-image-sign", "system-slot-image"):
        shutil.copy2(tree/"host-tools"/name, components/name)
    (base/'mdp-inputs.json').write_text(json.dumps({'lock_sha256':digest(lock),'tree':str(tree),'variant':variant},indent=2)+'\n')


def main():
    """Consume a fixed artifact lock; a missing artifact is an error, never a build request."""
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root',type=Path,required=True)
    parser.add_argument('--lock',type=Path)
    parser.add_argument('--variant',choices=['system','installer'],default='system')
    args=parser.parse_args()
    root=args.root.resolve()
    sys.path.insert(0,str(root/'tools/mdp/src'))
    from mdp.cli import Error as MDPError
    try:stage(root,args.lock or root/'mdp.assembly.lock',args.variant)
    except (Error,MDPError,OSError,ValueError,KeyError,TypeError,subprocess.CalledProcessError,tarfile.TarError) as error:
        print('image assembly: '+str(error),file=sys.stderr);return 1
    return 0


if __name__=='__main__':raise SystemExit(main())
