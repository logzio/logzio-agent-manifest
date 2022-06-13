const fs = require('fs')
const path = require('path')

const posts = fs.readdir(
    path.join(process.env.GITHUB_WORKSPACE, 'manifest')
)

async function run() {
    console.log('Hello, world!');
    console.log(posts);
}

run();
