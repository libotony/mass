import * as Express from 'express'

const api = Express()
export = api

api.use('/blocks', require('./blocks'))
api.use('/accounts', require('./accounts'))
