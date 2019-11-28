import { Router } from 'express'
import { try$, HttpError } from 'express-toolbox'
import { isHexBytes } from '../validator'
import { getAccount, getTokenBalance, countAccountTransaction, getAccountTransaction, getAccountTransfer, getAccountTransferByType, countAccountTransferByType, countAccountTransfer } from '../db-service/account'
import { getAuthority, getSignedBlocks } from '../db-service/authority'
import { AssetType } from '../explorer-db/types'
import { parseOffset, parseLimit, DEFAULT_LIMIT, BLOCK_INTERVAL, ENERGY_GROWTH_RATE } from '../utils'

const router = Router()
export = router

router.get('/:address', try$(async (req, res) => {
    if (!isHexBytes(req.params.address)) {
        throw new HttpError(400, 'invalid address')
    }
    const addr = req.params.address
    let account = await getAccount(addr)
    const t = await getTokenBalance(addr)
    const authority = await getAuthority(addr)
    if (!account) {
        account = {
            address: addr,
            balance: BigInt(0),
            energy: BigInt(0),
            blockTime: 0,
            code: null,
            master: null,
            sponsor: null
        }
    }
    const token: Array<{symbol:string, balance:bigint}> = []
    for (let x of t) {
        token.push({ symbol: AssetType[x.type], balance: x.balance })
    }
    
    const ts = Math.floor(new Date().getTime()/1000)
    const lastBlockTime = ts - ts % BLOCK_INTERVAL

    account.energy = account.energy + account.balance * BigInt(lastBlockTime - account.blockTime) * ENERGY_GROWTH_RATE/BigInt(1e18)
    
    res.json({
        account: {
            ...account,
            blockTime: undefined
        } ,
        token,
        authority: authority ? authority : null
    })
}))

router.get('/:address/transactions', try$(async (req, res) => {
    if (!isHexBytes(req.params.address)) {
        throw new HttpError(400, 'invalid address')
    }
    const addr = req.params.address
    const offset = req.query.offset ? parseOffset(req.query.offset) : 0
    const limit = req.query.limit ? parseLimit(req.query.limit) : DEFAULT_LIMIT

    const count = await countAccountTransaction(addr)
    if (!count || count <= offset) {
        return res.json({count, transactions:[]})
    }
    const raw = await getAccountTransaction(addr, offset, limit)
    const transactions = raw.map(x => {
        return {
            ...x,
            meta: {
                blockID: x.blockID,
                blockNumber: x.block.number,
                blockTimestamp: x.block.timestamp
            },
            block:undefined
        }
    })

    res.json({count,transactions})
}))

// query type limit offset
const AssetLiterals =  [  'VET', 'VTHO', 'PLA', 'SHA', 'EHrT', 'DBET', 'TIC', 'OCE', 'SNK', 'JUR', 'AQD', 'YEET']
router.get('/:address/transfers', try$(async (req, res) => {
    if (!isHexBytes(req.params.address)) {
        throw new HttpError(400, 'invalid address')
    }
    const addr = req.params.address
    const offset = req.query.offset ? parseOffset(req.query.offset) : 0
    const limit = req.query.limit ? parseLimit(req.query.limit) : DEFAULT_LIMIT

    let type: AssetType|null = null
    if (req.query.type) {
        if (AssetLiterals.indexOf(req.query.type) === -1) {
            throw new HttpError(400, 'invalid type')
        }
        type = AssetType[req.query.type as keyof typeof AssetType]
    }

    if (type === null) {
        const count = await countAccountTransfer(addr)
        if (!count || count <= offset) {
            return res.json({count, transfers:[]})
        }
        const raw = await getAccountTransfer(addr, offset, limit)
        const transfers = raw.map(x => {
            return {
                ...x,
                symbol: AssetType[x.type],
                type: undefined,
                meta: {
                    blockID: x.blockID,
                    blockNumber: x.block.number,
                    blockTimestamp: x.block.timestamp
                },
                block: undefined,
                blockID: undefined,
                id: undefined
            }
        })
        res.json({count,transfers})
    } else {
        const count = await countAccountTransferByType(addr, type)
        if (!count || count <= offset) {
            return res.json({count, transfers:[]})
        }
        const raw = await getAccountTransferByType(addr, type, offset, limit)
        const transfers = raw.map(x => {
            return {
                ...x,
                symbol: AssetType[x.type],
                type: undefined,
                meta: {
                    blockID: x.blockID,
                    blockNumber: x.block.number,
                    blockTimestamp: x.block.timestamp
                },
                block:undefined,
                blockID: undefined,
                id: undefined
            }
        })
        res.json({count,transfers})
    }
}))

router.get('/:address/signed', try$(async (req, res) => {
    if (!isHexBytes(req.params.address)) {
        throw new HttpError(400, 'invalid address')
    }
    const addr = req.params.address
    const offset = req.query.offset ? parseOffset(req.query.offset) : 0
    const limit = req.query.limit ? parseLimit(req.query.limit) : DEFAULT_LIMIT

    const auth = await getAuthority(addr)
    if (!auth) {
        throw new HttpError(400, 'not an authority')
    }

    const count = auth.signed
    if (!count || count <= offset) {
        return res.json({count, blocks:[]})
    }
    const blocks = await getSignedBlocks(addr, offset, limit)

    res.json({count, blocks})
}))
