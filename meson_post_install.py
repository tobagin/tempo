#!/usr/bin/env python3
"""Post-install script for Tempo metronome application."""

import os
import subprocess
import sys


def main():
    """Main post-install function."""
    destdir = os.environ.get('DESTDIR', '')
    datadir = os.path.join(destdir, sys.argv[1])
    
    print(f'Post-install debug: DESTDIR={destdir}')
    print(f'Post-install debug: datadir={datadir}')
    print(f'Post-install debug: sys.argv={sys.argv}')
    
    # Compile GSettings schemas
    print('Compiling GSettings schemas...')
    schema_dir = os.path.join(datadir, 'glib-2.0', 'schemas')
    
    if not os.path.exists(schema_dir):
        print(f'Schema directory {schema_dir} does not exist, creating it...')
        os.makedirs(schema_dir, exist_ok=True)
    
    try:
        subprocess.run([
            'glib-compile-schemas', schema_dir
        ], check=True)
        print('GSettings schemas compiled successfully')
    except subprocess.CalledProcessError as e:
        print(f'Failed to compile GSettings schemas: {e}')
        return
    except FileNotFoundError:
        print('glib-compile-schemas not found, skipping schema compilation')
    
    # Update desktop database
    print('Updating desktop database...')
    desktop_dir = os.path.join(datadir, 'applications')
    
    if os.path.exists(desktop_dir):
        try:
            subprocess.run([
                'update-desktop-database', desktop_dir
            ], check=True)
            print('Desktop database updated successfully')
        except subprocess.CalledProcessError as e:
            print(f'Failed to update desktop database: {e}')
        except FileNotFoundError:
            print('update-desktop-database not found, skipping desktop database update')
    
    # Update icon cache
    print('Updating icon cache...')
    icon_dir = os.path.join(datadir, 'icons', 'hicolor')
    
    if os.path.exists(icon_dir):
        try:
            subprocess.run([
                'gtk-update-icon-cache', '-f', '-t', icon_dir
            ], check=True)
            print('Icon cache updated successfully')
        except subprocess.CalledProcessError as e:
            print(f'Failed to update icon cache: {e}')
        except FileNotFoundError:
            print('gtk-update-icon-cache not found, skipping icon cache update')
    
    print('Post-install script completed')


if __name__ == '__main__':
    main()