import { HttpError } from 'express-toolbox'
import { isUInt } from '../validator'

export const MAX_LIMIT = 50
export const DEFAULT_LIMIT = 20
export const BLOCK_INTERVAL = 10
export const REVERSIBLE_WINDOW = 12

export const parseLimit = (limit: string, maximum=MAX_LIMIT):number => {
    const num = parseInt(limit)
    if (isNaN(num)||!isUInt(num)||!num) { 
        throw new HttpError(400, 'invalid limit')
    }
    if (num > maximum) {
        throw new HttpError(403, 'limit too large')
    }
    return num
}

export const parseOffset = (offset: string): number => {
    const num = parseInt(offset)
    if (isNaN(num)||!isUInt(num)) { 
        throw new HttpError(400, 'invalid limit')
    }
    return num
}

export const blockIDtoNum = (blockID: string) => {
    if (typeof blockID === 'string' && !/^0x[0-9a-fA-f]{64}$/i.test(blockID)) {
        throw new Error('bytes32 required as param but got: ' + blockID)
    }

    return parseInt(blockID.slice(0, 10), 16)
}
