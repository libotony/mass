import { HttpError } from 'express-toolbox'
import { isUInt } from '../validator'

export const MAX_LIMIT = 50
export const DEFAULT_LIMIT=20

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
