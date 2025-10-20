# Vala test files and their dependencies
vala_tests = {
  # Disabled tests that depend on GStreamer for now
  # 'test_metronome_engine': ['utils/MetronomeEngine.vala'],
  'test_tap_tempo': ['utils/TapTempo.vala'],
  # 'test_api_compatibility': ['utils/MetronomeEngine.vala', 'utils/TapTempo.vala'],
}

# Build and run Vala tests
foreach test_name, source_files : vala_tests
  # Create full paths for source files
  full_sources = [join_paths(meson.current_source_dir(), test_name + '.vala')]
  foreach src_file : source_files
    full_sources += [join_paths(meson.project_source_root(), 'src', src_file)]
  endforeach
  
  test_exe = executable(test_name,
    full_sources,
    dependencies: [
      glib_dep,
      gobject_dep,
    ],
    vala_args: [
      '--pkg=glib-2.0',
      '--pkg=gobject-2.0',
    ],
    link_args: ['-lm'], # Link with math library for round() function
  )
  
  test(test_name, test_exe, timeout: 30)
endforeach