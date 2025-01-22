# this retains the intermediate files
.PRECIOUS: %.s %.obj
CC=pblaze-cc.py -g
AS=pblaze-as.py
LD=pblaze-ld.py

# pblaze-ld/pblaze-as flags
CFLAGS=-l
LDFLAGS=--dualport
ASFLAGS=-6

# target. Change this only (other than flags).
all: pb_turfio.v pb_turfio.hex

clean:
	rm -rf *.v
	rm -rf *.obj
	rm -rf *.s
	rm -rf *.hex

%.s : %.c $(DEPENDS)
	$(CC) $(CFLAGS) $<

%.obj : %.s
	$(AS) $(ASFLAGS) $<

%.hex : %.s
	$(AS) $(ASFLAGS) --hex $<

%.v : %.obj
	$(LD) $(LDFLAGS) $<


