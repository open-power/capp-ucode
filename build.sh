#!/bin/bash


# #define PNOR_SUBPART_HEADER_SIZE 0x1000
# struct pnor_hostboot_toc {
# 	be32 ec;
# 	be32 offset; /* from start of header.  4K aligned */
# 	be32 size; /* */
# };
# #define PNOR_HOSTBOOT_TOC_MAX_ENTRIES ((PNOR_SUBPART_HEADER_SIZE - 8)/sizeof(struct pnor_hostboot_toc))
# struct pnor_hostboot_header {
# 	char eyecatcher[4];
# 	be32 version;
# 	struct pnor_hostboot_toc toc[PNOR_HOSTBOOT_TOC_MAX_ENTRIES];
# };

align() {
    echo $(( (($1 + ($alignment - 1))) & ~($alignment - 1) ))
}

phb3=0

phb3=$(( $phb3 + 1))
phb3id[$phb3]=$(( 0x100ea ))
phb3file[$phb3]="CAPPUC_P8V10.bin"

phb3=$(( $phb3 + 1))
phb3id[$phb3]=$(( 0x200ea ))
phb3file[$phb3]="CAPPUC_P8V20.bin"

phb3=$(( $phb3 + 1))
phb3id[$phb3]=$(( 0x200ef ))
phb3file[$phb3]="CAPPUC_P8M20.bin"

phb3=$(( $phb3 + 1))
phb3id[$phb3]=$(( 0x201ef ))
phb3file[$phb3]="CAPPUC_P8M21.bin"

phb3=$(( $phb3 + 1))
phb3id[$phb3]=$(( 0x100d3 ))
phb3file[$phb3]="CAPPUC_P8N10.bin"

phb3=$(( $phb3 + 1))
phb3id[$phb3]=$(( 0x100d1 ))
phb3file[$phb3]="CAPPUC_P9N10.bin"

phb3=$(( $phb3 + 1))
phb3id[$phb3]=$(( 0x200d1 ))
phb3file[$phb3]="CAPPUC_P9N20.bin"

phb3=$(( $phb3 + 1))
phb3id[$phb3]=$(( 0x201d1 ))
phb3file[$phb3]="CAPPUC_P9N21.bin"

phb3=$(( $phb3 + 1))
phb3id[$phb3]=$(( 0x202d1 ))
phb3file[$phb3]="CAPPUC_P9N22.bin"

debug=true
if [ -n "$DEBUG" ] ; then
    debug=echo
fi

TMPFILE=$(mktemp)

EYECATCHER=$(( 0x43415050 )) # ascii 'CAPP'
VERSION=1
NUMBEROFTOCENTRIES=$phb3

printf "0: %.8x" $EYECATCHER | xxd -r -g0 >> $TMPFILE
printf "0: %.8x" $VERSION | xxd -r -g0 >> $TMPFILE

sections=0
alignment=$(( 0x1000 ))
offset=$alignment
# Add IDs
for i in $(seq $NUMBEROFTOCENTRIES) ; do
    # Work out if we added this file already
    matched=0
    for s in $(seq $sections); do
	if cmp -s ${phb3file[$i]} ${sectionfile[$s]} ; then
	    $debug matched ${phb3file[$i]} ${sectionfile[$s]}
	    matched=1
	    section=$s
	    break 1
	fi
    done
    if [ $matched == 0 ] ; then
	sections=$(( $sections + 1 ))
	sectionfile[$sections]=${phb3file[$i]}
	sectionsize[$sections]=$( stat -c %s ${sectionfile[$sections]} )
	sectionoffset[$sections]=$(align $offset)
	offset=$(( ${sectionoffset[$sections]} + ${sectionsize[$sections]} ))
	$debug Adding section ${phb3file[$i]} size: ${sectionsize[$sections]} offset: ${sectionoffset[$sections]}
	section=$sections
    fi

    # Add TOC entry for every PHB3 to
    printf "0: %.8x" ${phb3id[$i]} | xxd -r -g0 >> $TMPFILE
    printf "0: %.8x" ${sectionoffset[$section]} | xxd -r -g0 >> $TMPFILE
    printf "0: %.8x" ${sectionsize[$section]} | xxd -r -g0 >> $TMPFILE
done
# write zeros to alignment
bytes=$(( $alignment - 8 - ($NUMBEROFTOCENTRIES * 12) ))
dd if=/dev/zero count=$bytes bs=1 >> $TMPFILE

# Add file sections
for i in $(seq $sections) ; do
    cat ${sectionfile[$i]} >> $TMPFILE

    # write zeros to alignment
    bytes=$(( $(align ${sectionsize[$i]}) - ${sectionsize[$i]} ))
    dd if=/dev/zero count=$bytes bs=1 >> $TMPFILE
done

mv $TMPFILE cappucode.bin

rm -rf $TMPFILE
