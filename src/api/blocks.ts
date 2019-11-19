import { Router } from 'express'
import { try$ } from 'express-toolbox'

const router = Router()
export = router

router.get('/:id', try$(async (req, res) => {
    res.end('hello world')
}))
