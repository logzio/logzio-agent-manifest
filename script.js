const fs = require('fs')
const path = require('path')

const posts = fs.readdir(
    path.join(process.env.GITHUB_WORKSPACE, 'content', 'posts')
)

async function run() {
    console.log('Hello, world!');
}

run();
