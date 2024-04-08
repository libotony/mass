# Mass

Backend of VeChain Official [Explorer](https://explore.vechain.org).

## API

+ `GET /api/accounts/:addr` - Get account summary
+ `GET /api/account/:addr/transactions` - Get transactions of account <sup>i</sup>
+ `GET /api/account/:addr/transfers` - Get Token transfers of account <sup>i</sup>
+ `GET /api/blocks/:revision` - Get block, revision can be `best`, `block number` or `block ID`
+ `GET /api/blocks/:blockid/transactions` - Get block transactions
+ `GET /api/blocks/recent` - Get recent blocks
+ `GET /api/transactions/:txid` - Get transaction
+ `GET /api/transactions/recent` - Get recent transactions
+ `GET /api/transfers/recent` - Get recent transfers

<b>i</b> : List API have the functionality of pagination, just specify `limit` and `offset` as the URL parameter. 

## Run Mass

### Clone Source

``` shell
git clone --recursive https://github.com/vechain/mass.git
cd mass
```

### Dependency && Build

``` shell
npm ci 
npm run build
```

### Configure Typeorm

Follow the official [instruction](https://typeorm.io/#/using-ormconfig), configure your local project.

### Start Server

``` shell
npm start
```

### Setting up the local environment

Build docker images for the following repos. 
```
git clone --recursive https://github.com/vechain/mass
cd mass
docker build . -t vechain/mass

git clone https://github.com/vechain/explorer
cd explorer
docker build . -t vechain/explorer

git clone --recursive https://github.com/vechain/chain-scanner
cd chain-scanner
docker build . -t vechain/chain-scanner
```

#### Spin up the project for local environment
```
cp .env.example .env
```

```
TYPEORM_CONNECTION=mysql
TYPEORM_HOST=db
TYPEORM_USERNAME=user
TYPEORM_PASSWORD=password
TYPEORM_DATABASE=chain
TYPEORM_PORT=3306
TYPEORM_ENTITIES=dist/explorer-db/entity/*.js
TYPEORM_MIGRATIONS=dist/migrations/*.js
THOR_REST=https://mainnet.live.dev.node.vechain.org
NETWORK=mainnet
NODE_ENV=production
API_URL=http://api:3000
CAPTCHA_SECRET=CAPTCHA_SECRET
```

#### Spin up the project pointing to the local environment by running docker compose

```
docker compose up
```

