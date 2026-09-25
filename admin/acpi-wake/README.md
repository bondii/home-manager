# ACPI USB-C wake workaround (Arch administrator setup)

These assets preserve the existing workaround for XHC0, XHC3, XHC4, NHI0 and
NHI1. The helper disables only currently enabled wake sources; the sleep hook
runs it after resume. There is no new boot service.

Home Manager no longer installs these files. Existing installed copies remain
active, including when the laptop feature is disabled or a generation is rolled
back. Updating this repository does not update installed copies.

Run these commands explicitly from the repository root when administering the
machine. First compare the files (a missing file is expected on a new machine):

```sh
diff -u /usr/local/sbin/disable-acpi-wake-usbc admin/acpi-wake/disable-acpi-wake-usbc
diff -u /usr/lib/systemd/system-sleep/disable-acpi-wake-usbc admin/acpi-wake/system-sleep-hook
```

Back up any existing files before installing; retain the printed directory for
rollback. These commands do not execute the wake helper:

```sh
acpi_backup=$(sudo mktemp -d /var/tmp/acpi-wake-backup.XXXXXXXX)
printf 'Backup directory: %s\n' "$acpi_backup"
if [ -f /usr/local/sbin/disable-acpi-wake-usbc ]; then
  sudo cp -p /usr/local/sbin/disable-acpi-wake-usbc "$acpi_backup/helper"
fi
if [ -f /usr/lib/systemd/system-sleep/disable-acpi-wake-usbc ]; then
  sudo cp -p /usr/lib/systemd/system-sleep/disable-acpi-wake-usbc "$acpi_backup/hook"
fi
sudo install -Dm0755 admin/acpi-wake/disable-acpi-wake-usbc /usr/local/sbin/disable-acpi-wake-usbc
sudo install -Dm0755 admin/acpi-wake/system-sleep-hook /usr/lib/systemd/system-sleep/disable-acpi-wake-usbc
```

Repeating installation produces the same contents and executable modes. To
restore a backup, use `sudo install -Dm0755` with the saved `helper` and `hook`
files as sources and the corresponding exact targets above.

To uninstall, first compare the installed files with the assets and confirm
they still belong to this workaround, then remove only these two files:

```sh
sudo rm -f /usr/lib/systemd/system-sleep/disable-acpi-wake-usbc /usr/local/sbin/disable-acpi-wake-usbc
```

Removal prevents future post-resume runs; it does not immediately re-enable
sources already disabled in `/proc/acpi/wakeup`. Validate desired wake behavior
after a reboot. Do not run these administrator commands as a repository test.
