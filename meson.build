project('nota', 'cpp', version: '4.0.5', meson_version: '>=1.12.0', default_options: ['cpp_std=c++17', 'buildtype=release'])

qt6 = import('qt6')
cpp_compiler = meson.get_compiler('cpp')
if cpp_compiler.get_id() == 'gcc' and cpp_compiler.has_argument('-Wno-sfinae-incomplete')
    add_project_arguments('-Wno-sfinae-incomplete', language: 'cpp')
endif
qt = dependency('qt6', version: '>=6.9', modules: ['Core', 'Qml', 'Quick', 'Widgets', 'DBus'])
kf6_core = dependency('KF6CoreAddons', version: '>=6.13')
kf6_i18n = declare_dependency(
    include_directories: include_directories(get_option('prefix') / 'include' / 'KF6' / 'KI18n'),
    dependencies: [cpp_compiler.find_library('KF6I18n'), cpp_compiler.find_library('KF6I18nQml')],
)
mauikit = dependency('MauiKit4', version: '>=4.0.5')
mauikit_filebrowsing = dependency('MauiKitFileBrowsing4', version: '>=4.0.5')
mauikit_texteditor = dependency('MauiKitTextEditor4', version: '>=4.0.5')

cpp_args = ['-DAPP_COPYRIGHT_NOTICE="© 2019-2025 Maui Development Team"']
if host_machine.cpu_family() == 'x86_64'
    cpp_args += ['-march=x86-64-v3']
endif
nota_version = configure_file(
    input: 'meson-content.in',
    output: 'nota_version.h',
    configuration: {'CONTENT': ('''#pragma once
#define NOTA_VERSION_STRING "4.0.5"
#define GIT_BRANCH "Stable"
#define GIT_COMMIT_HASH "4.0.5"
''')}
)
nota_includes = include_directories('src')

qdbuscpp2xml = find_program('qdbuscpp2xml')
qdbusxml2cpp = find_program('qdbusxml2cpp')
dbus_xml = custom_target('nota-dbus-xml', input: 'src/controllers/server.h', output: 'org.kde.Nota.xml', command: [qdbuscpp2xml, '-o', '@OUTPUT@', '@INPUT@'])
dbus_adaptor = custom_target('nota-dbus-adaptor', input: dbus_xml, output: ['notaadaptor.cpp', 'notaadaptor.h'], command: [qdbusxml2cpp, '-a', 'notaadaptor', '@INPUT@'])
dbus_interface = custom_target('nota-dbus-interface', input: dbus_xml, output: ['notainterface.cpp', 'notainterface.h'], command: [qdbusxml2cpp, '-p', 'notainterface', '@INPUT@'])
qt_sources = qt6.preprocess(
    qresources: ['src/assets/img_assets.qrc', 'src/qml.qrc'],
    moc_headers: ['src/models/historymodel.h', 'src/controllers/server.h', dbus_adaptor[1], dbus_interface[1]],
)

nota_sources = [
    'src/main.cpp',
    'src/models/historymodel.cpp',
    'src/controllers/server.cpp',
]

executable(
    'nota',
    nota_sources + [dbus_adaptor, dbus_interface] + qt_sources + [nota_version],
    dependencies: [qt, kf6_core, kf6_i18n, mauikit, mauikit_filebrowsing, mauikit_texteditor],
    include_directories: nota_includes, cpp_args: cpp_args,
    install: true,
)

install_data('org.maui.nota.desktop', install_dir: get_option('datadir') / 'applications')
install_data('org.maui.nota.metainfo.xml', install_dir: get_option('datadir') / 'metainfo')
