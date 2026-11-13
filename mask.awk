BEGIN { 
    FS = OFS = "\t" 
}

{
    # 1. Store current line
    line[NR] = $0

    # 2. Flag current line and surrounding window if rate >= 100
    if ($3 >= 100) {
        for (i = NR - w; i <= NR + w; i++) {
            if (i > 0) mask[i] = 1
        }
    }

    # 3. Process line falling out of the window
    out = NR - w
    if (out > 0) {
        process_line(out)
    }
}

END {
    # 4. Process remaining lines in buffer
    for (out = NR - w + 1; out <= NR; out++) {
        if (out > 0 && line[out] != "") {
            process_line(out)
        }
    }

    # 5. Output summary metrics to stderr
    print "\n=== MASKING SUMMARY ===" > "/dev/stderr"
    print "Total SNPs (lines) masked: " total_snps_masked > "/dev/stderr"
    print "Total contiguous regions:  " total_regions_masked > "/dev/stderr"
}

# Helper function to track metrics and print stream sequentially
function process_line(idx) {
    if (mask[idx]) {
        total_snps_masked++
        
        # If we weren't already in a region, this starts a new one
        if (!in_region) {
            total_regions_masked++
            in_region = 1
        }
        
        $0 = line[idx]
        $3 = 0
        print $0
    } else {
        # Mark that we've exited a masked region
        in_region = 0
        print line[idx]
    }
    
    delete line[idx]
    delete mask[idx]
}
