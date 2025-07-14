# Test configuration
test_env = environment()
test_env.set('PYTHONPATH', meson.project_source_root())

# Python test files
test_files = [
  'test_metronome.py',
  'test_audio.py',
  'test_window.py'
]

# Find pytest
pytest = find_program('pytest', required: false)

if pytest.found()
  foreach test_file : test_files
    test_name = fs.stem(test_file)
    test(
      test_name,
      pytest,
      args: [
        join_paths(meson.current_source_dir(), test_file),
        '-v'
      ],
      env: test_env,
      timeout: 30
    )
  endforeach
else
  message('pytest not found, skipping tests')
endif