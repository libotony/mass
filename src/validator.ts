export function isHexString(val: string) {
    return typeof val === 'string' && /^0x[0-9a-f]+$/i.test(val)
}

export function isHexBytes(val: string, n?: number) {
    if (typeof val !== 'string' || !/^0x[0-9a-f]*$/i.test(val)) {
        return false
    }
    return n ? val.length === n * 2 + 2 : val.length % 2 === 0
}

export function isUInt(val: number) {
    if (val < 0 || !Number.isInteger(val)) {
        return false
    }
    return true
}
