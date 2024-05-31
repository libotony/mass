import { Router } from 'express'
import { try$ } from 'express-toolbox'
import { getConnection } from 'typeorm'
import { Config } from '../explorer-db/entity/config'
import { getBest } from '../db-service/block'
import { BLOCK_INTERVAL } from '../utils'
import { listTokens } from '../token'

const tolerableBlockGap = 6

const router = Router()
export = router

interface Overview {
    ok: boolean
    tasks: Array<{
        name: string
        blocks: number
    }>
}

router.get('/overview', try$(async (req, res) => { 
    const best = await getBest()
    const now = Math.floor(new Date().getTime() / 1000)
    const targetTime = now - now % BLOCK_INTERVAL
    
    if (best.timestamp < targetTime - tolerableBlockGap*BLOCK_INTERVAL) { 
        return res.json({
            ok: false,
            tasks: [
                {name: 'blockchain', blocks: (targetTime-best.timestamp)/BLOCK_INTERVAL}
            ]
        })
    }

    const tasks = await getConnection().getRepository(Config).find()

    const overview: Overview = {
        ok: true,
        tasks: []
    }

    const check = (name: string, key: string) => {
        const index = tasks.findIndex(x => x.key === key)
        
        if (index < 0) {
            // ignore missing token task
            if (!name.startsWith('token-')) { 
                overview.tasks.push({ name, blocks: -1 })
            }
            return
        }

        const task = tasks[index]
        const head = Number.parseInt(task.value)
        if ( head < best.number - tolerableBlockGap) { 
            overview.tasks.push({name: name, blocks: best.number - head})
        }
    }

    check('tx', 'expand-tx-head')
    check('dual-token', 'dual-token-head')
    check('authority', 'authority-head')
    check('revert', 'revert-head')

    const tokens = listTokens()
    for (const token of tokens) {
        if (token === 'VET' || token === 'VTHO') { 
            continue
        }
        check(`token-${token}`, `token-${token}-head`)
    }

    res.json(overview)
}))