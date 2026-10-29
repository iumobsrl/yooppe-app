#!/usr/bin/env python3
"""
Genera le cartelle android/ e ios/ e applica le configurazioni richieste
(permessi, notifiche programmate, accesso alle foto, icona).

Uso (dalla cartella del progetto):
  Mac:      python3 tool/configura_piattaforme.py
  Windows:  python tool\\configura_piattaforme.py
Si può rilanciare senza problemi: le modifiche già presenti non vengono duplicate.
"""
import os
import plistlib
import re
import shutil
import subprocess
import sys

try:
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
except Exception:
    pass

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)

ORG = 'com.yooppe'          # cambia qui l'identificativo (es. com.tuaazienda) PRIMA del primo lancio
APP_LABEL = 'Yooppe'


def run(cmd):
    print('→', ' '.join(cmd))
    exe = shutil.which(cmd[0])  # su Windows trova flutter.bat / dart.bat
    if not exe:
        sys.exit(f'Comando non trovato: {cmd[0]}')
    r = subprocess.run([exe] + cmd[1:])
    if r.returncode != 0:
        sys.exit(f'\nComando non riuscito: {" ".join(cmd)}')


def ok(msg):
    print('  ✓', msg)


def warn(msg):
    print('  ! ' + msg)


if not shutil.which('flutter'):
    sys.exit('Flutter non trovato. Installa Flutter (https://docs.flutter.dev/get-started/install) e riprova.')

# 1) Cartelle native
IS_MAC = sys.platform == 'darwin'
if not os.path.isdir('android') or (IS_MAC and not os.path.isdir('ios')):
    run(['flutter', 'create', '--org', ORG, '--project-name', 'yooppe', '--platforms', 'android,ios', '.'])
else:
    ok('cartelle native già presenti')

# 2) Android: permessi e ricevitori per le notifiche programmate
mf = 'android/app/src/main/AndroidManifest.xml'
s = open(mf, encoding='utf-8').read()
perms = ['android.permission.INTERNET', 'android.permission.POST_NOTIFICATIONS',
         'android.permission.RECEIVE_BOOT_COMPLETED', 'android.permission.VIBRATE']
add = ''.join(f'    <uses-permission android:name="{p}"/>\n' for p in perms if p not in s)
if add:
    s = s.replace('    <application', add + '    <application', 1)
receivers = '''        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
'''
if 'ScheduledNotificationReceiver' not in s:
    s = s.replace('    </application>', receivers + '    </application>', 1)
s = re.sub(r'android:label="[^"]*"', f'android:label="{APP_LABEL}"', s, count=1)
open(mf, 'w', encoding='utf-8').write(s)
ok('AndroidManifest: permessi, ricevitori notifiche, nome app')

# 3) Android: "desugaring" richiesto da flutter_local_notifications
kts, groovy = 'android/app/build.gradle.kts', 'android/app/build.gradle'
if os.path.exists(kts):
    g = open(kts, encoding='utf-8').read()
    if 'isCoreLibraryDesugaringEnabled' not in g:
        g = re.sub(r'compileOptions\s*\{', 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true', g, count=1)
    if 'desugar_jdk_libs' not in g:
        g += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
    open(kts, 'w', encoding='utf-8').write(g)
    ok('build.gradle.kts: desugaring attivato')
elif os.path.exists(groovy):
    g = open(groovy, encoding='utf-8').read()
    if 'coreLibraryDesugaringEnabled' not in g:
        g = re.sub(r'compileOptions\s*\{', 'compileOptions {\n        coreLibraryDesugaringEnabled true', g, count=1)
    if 'desugar_jdk_libs' not in g:
        g += "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n"
    open(groovy, 'w', encoding='utf-8').write(g)
    ok('build.gradle: desugaring attivato')
else:
    warn('build.gradle non trovato: attiva a mano il "core library desugaring" (vedi LEGGIMI.md)')

# 4) iOS: testi per l'accesso alle foto e nome app
pl = 'ios/Runner/Info.plist'
if os.path.exists(pl):
    with open(pl, 'rb') as f:
        d = plistlib.load(f)
    d['CFBundleDisplayName'] = APP_LABEL
    d.setdefault('NSPhotoLibraryUsageDescription', 'Serve per scegliere la foto del profilo o inviare una foto in chat.')
    d.setdefault('NSCameraUsageDescription', 'Serve per scattare la foto del profilo o una foto da inviare in chat.')
    d['UISupportedInterfaceOrientations'] = ['UIInterfaceOrientationPortrait']
    with open(pl, 'wb') as f:
        plistlib.dump(d, f)
    ok('Info.plist: permessi foto/fotocamera, nome app, solo verticale')
else:
    warn('cartella iOS assente: normale su Windows (l\'app iPhone si compila solo da Mac)')

# 5) iOS: tocco sulle notifiche (delegate del centro notifiche)
ad = 'ios/Runner/AppDelegate.swift'
if os.path.exists(ad):
    a = open(ad, encoding='utf-8').read()
    if 'UNUserNotificationCenter' not in a:
        if 'GeneratedPluginRegistrant.register(with: self)' in a:
            a = a.replace('import Flutter', 'import Flutter\nimport UserNotifications', 1)
            a = a.replace('GeneratedPluginRegistrant.register(with: self)',
                          'UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate\n    GeneratedPluginRegistrant.register(with: self)', 1)
            open(ad, 'w', encoding='utf-8').write(a)
            ok('AppDelegate.swift: delegate notifiche')
        else:
            warn('AppDelegate.swift ha un formato diverso dal previsto: vedi LEGGIMI.md, sezione iOS')
    else:
        ok('AppDelegate.swift già configurato')

# 6) Pacchetti e icone
run(['flutter', 'pub', 'get'])
run(['dart', 'run', 'flutter_launcher_icons'])

print('\nFatto. Collega un telefono o apri un simulatore e lancia:  flutter run')
