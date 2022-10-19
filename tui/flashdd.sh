# HOW TO CLONE / FLASH FROM CLI

# Compression rates:
# https://www.rootusers.com/gzip-vs-bzip2-vs-xz-performance-comparison/


# Clone - dd flash with pv - gzip
pv /dev/sda | gzip > /mnt/backup/nprohd.img.gz
pv /dev/sda2 | zstd -16 > /mnt/backup/nprohd.zst

# Flash
gzcat /mnt/backup/nprohd.img.gz | pv > /dev/sda3
gunzip -c /mnt/backup/nprohd.img.gz | pv > /dev/sda3

## dd flash with pv - zstd
zstdzcat /mnt/backup.img.zst | pv >/dev/sda3

dd bs=1M iflag=fullblock if=/dev/sda status=progress | gzip > /mnt/backup/nprohd.img.gz
gzcat /mnt/usb/nprohd.img.gz | dd bs=1M iflag=fullblock of=/dev/sda2          status=progress

dd bs=1M iflag=fullblock if=/dev/sda2 status=progress | zstd -16v > /mnt/backup/nprohd.img.zst
zstdcat /mnt/usb/nprohd.img.zst | dd bs=1M iflag=fullblock of=/dev/sda2       status=progress

