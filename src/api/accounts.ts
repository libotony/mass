import { Router } from 'express'
import { try$, HttpError } from 'express-toolbox'
import { isHexBytes, isUInt } from '../validator'
import { getAccount, getTokenBalance, countAccountTransaction, getAccountTransaction, getAccountTransfer, getAccountTransferByType, countAccountTransferByType } from '../explorer-db/service/account'
import { getAuthority, getSignedBlocks } from '../explorer-db/service/authority'
import { AssetType } from '../explorer-db/types'

const router = Router()
export = router

router.get('/:address', try$(async (req, res) => {
    if (!isHexBytes(req.params.address)) {
        throw new HttpError(400, 'invalid address')
    }
    const addr = req.params.address
    const account = await getAccount(addr)
    const t = await getTokenBalance(addr)
    const authority = await getAuthority(addr)
    if (!account && !t.length && !authority) {
        throw new HttpError(404, 'address not found')
    }
    const token: {[key:string]:bigint} ={}
    for (let x of t) {
        token[AssetType[x.type]] = x.balance
    }
    
    res.json({
        account: account ? account : null,
        token,
        authority: authority ? authority : null
    })
}))

router.get('/:address/transactions', try$(async (req, res) => {
    if (!isHexBytes(req.params.address)) {
        throw new HttpError(400, 'invalid address')
    }
    const addr = req.params.address
    let offset = 0
    if (req.query.limit) {
        const num = parseInt(req.query.limit)
        if (isNaN(num)||!isUInt(num)) { 
            throw new HttpError(400, 'invalid limit')
        }
        offset = num
    }
    let limit = 12
    if (req.query.limit) {
        const num = parseInt(req.query.limit)
        if (isNaN(num)||!isUInt(num) || !num || num>50) { 
            throw new HttpError(400, 'invalid limit')
        }
        limit = num
    }
    const count = await countAccountTransaction(addr)
    if (!count) {
        return res.json({count, transactions:[]})
    }
    const transactions = await getAccountTransaction(addr, offset, limit)

    res.json({count,transactions})
}))

// query type limit offset
const AssetLiterals =  [  'VET', 'Energy', 'PLA', 'SHA', 'EHrT', 'DBET', 'TIC', 'OCE', 'SNK', 'JUR', 'AQD', 'YEET']
router.get('/:address/transfers', try$(async (req, res) => {
    if (!isHexBytes(req.params.address)) {
        throw new HttpError(400, 'invalid address')
    }
    const addr = req.params.address
    let offset = 0
    if (req.query.limit) {
        const num = parseInt(req.query.limit)
        if (isNaN(num)||!isUInt(num)) { 
            throw new HttpError(400, 'invalid limit')
        }
        offset = num
    }
    let limit = 12
    if (req.query.limit) {
        const num = parseInt(req.query.limit)
        if (isNaN(num)||!isUInt(num) || !num || num>50) { 
            throw new HttpError(400, 'invalid limit')
        }
        limit = num
    }
    let type: AssetType|null = null
    if (req.query.type) {
        if (AssetLiterals.indexOf(req.query.type) === -1) {
            throw new HttpError(400, 'invalid type')
        }
        type = AssetType[req.query.type as keyof typeof AssetType]
    }

    if (type === null) {
        const count = await countAccountTransaction(addr)
        if (!count) {
            return res.json({count, transfers:[]})
        }
        const transfers = await getAccountTransfer(addr, offset, limit)
        res.json({count,transfers})
    } else {
        const count = await countAccountTransferByType(addr, type)
        if (!count) {
            return res.json({count, transfers:[]})
        }
        const transfers = await getAccountTransferByType(addr, type, offset, limit)
        res.json({count,transfers})
    }
}))

router.get('/:address/signed', try$(async (req, res) => {
    if (!isHexBytes(req.params.address)) {
        throw new HttpError(400, 'invalid address')
    }
    const addr = req.params.address
    let offset = 0
    if (req.query.limit) {
        const num = parseInt(req.query.limit)
        if (isNaN(num)||!isUInt(num)) { 
            throw new HttpError(400, 'invalid limit')
        }
        offset = num
    }
    let limit = 12
    if (req.query.limit) {
        const num = parseInt(req.query.limit)
        if (isNaN(num)||!isUInt(num) || !num || num>50) { 
            throw new HttpError(400, 'invalid limit')
        }
        limit = num
    }
    const auth = await getAuthority(addr)
    if (!auth) {
        throw new HttpError(400, 'not an authority')
    }
    if (!auth.signed) {
        return res.json({count:auth.signed, blocks:[]})
    }
    const blocks = await getSignedBlocks(addr, offset, limit)

    res.json({count:auth.signed,blocks})
}))
