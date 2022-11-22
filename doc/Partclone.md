# Partclone

## Background

Why we use partclone?
- partclone backups are smaller than dd clone
- because the don't copy empty space


## Usage

### Basic:
`partclone.ext4 -c -s /dev/fingolfin_vg/home_snap_lv -o /mnt/data/backup.pcl

-c clone
-s source
-o output

### Clone with ncurses (tui):
`partclone.ext4 -N -c -s  /dev/fingolfin_vg/home_snap_lv -o /mnt/data/backup.pcl



### Clone with compression:
`partclone.ext4 -c -s /dev/fingolfin_vg/home_snap_lv | gzip -c -9 > /mnt/data/backup.pcl`

The compression level to be used is set with the -9 option, the maximum available. 
Default compression rate is -6. Alternatively --fast can be used to use the fastest 
compression, favoring speed against efficiency, or, vice versa, --best for the 
opposite behavior, obtaining the smallest file.


### Restore
partclone.ext4 -r -s /mnt/data/backup.pcl -o /dev/fingolfin_vg/home_snap_lv

gzip -c -d /mnt/data/backup.pcl.gz | partclone.ext4 -r -o /dev/fingolfin_vg/home_snap_lv

zcat /mnt/data/backup.pcl.gz | partclone.ext4 -r -o /dev/fingolfin_vg/home_snap_lv



## Partclone commands

https://partclone.org/usage/partclone.restore.php



### Restore (uncompressed)

Restore boot:   partclone.dd      -N -s pcm300F_uncompressed_32G/pcm300F_sda1_boot.pcl      -o /dev/sda1
Restore system: partclone.ext4 -r -N -s pcm300F_uncompressed_32G/pcm300F_sda2_system.pcl    -o /dev/sda2
Restore data:   partclone.vfat -r -N -s pcm300F_uncompressed_32G/pcm300F_sda3_data.pcl      -o /dev/sda3

### Clone

Clone boot:     partclone.dd      -N -s /dev/sda1   -o pcmXXX_sda1_boot.pcl
Clone system:   partclone.ext  -c -N -s /dev/sda2   -o pcmXXX_sda2_system.pcl
Clone data:     partclone.vfat -c -N -s /dev/sda3   -o pcmXXX_sda3_data.pcl







## Further readings:
Partclone
https://linuxconfig.org/how-to-use-partclone-to-create-a-smart-partition-backup
