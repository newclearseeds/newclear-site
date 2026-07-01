function Confirm-SafeDisk {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$DiskNumber,
        [string]$ExpectedBusType = 'USB',
        [switch]$RequireTypedConfirmation,
        [switch]$DryRun
    )

    if ($DryRun) {
        Write-Host "[DRYRUN] Validate disk $DiskNumber before destructive media write."
        return $true
    }

    $disk = Get-Disk -Number $DiskNumber -ErrorAction Stop
    $details = "Disk {0}: {1}, {2:n1} GB, Bus={3}, PartitionStyle={4}, IsBoot={5}, IsSystem={6}" -f `
        $disk.Number, $disk.FriendlyName, ($disk.Size / 1GB), $disk.BusType, $disk.PartitionStyle, $disk.IsBoot, $disk.IsSystem
    Write-Host $details

    if ($disk.IsBoot -or $disk.IsSystem) {
        throw "Refusing to target boot/system disk $DiskNumber."
    }

    if ($ExpectedBusType -and ([string]$disk.BusType) -ne $ExpectedBusType) {
        throw "Refusing disk $DiskNumber because BusType is '$($disk.BusType)', expected '$ExpectedBusType'."
    }

    if ($RequireTypedConfirmation) {
        $expected = "WIPE DISK $DiskNumber"
        $actual = Read-Host "Type '$expected' to continue"
        if ($actual -ne $expected) {
            throw "Disk confirmation did not match. No changes were made."
        }
    }

    return $true
}
