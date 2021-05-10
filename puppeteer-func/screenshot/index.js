const puppeteer = require('puppeteer');

module.exports = async function (context, req) {

    const url = req.query.url || (req.body && req.body.url);
    context.log(`Analyzing URL ${url}`);

    const browser = await puppeteer.launch({
        defaultViewport: { width: 1920, height: 1080 },
        args: ['--no-sandbox']
    });

    const page = await browser.newPage();
    await page.goto(url);
    await page.waitForTimeout(2000);
    const screenshotBuffer = await page.screenshot({ fullPage: true });
    await browser.close();

    context.res = {
        body: `data:image/png;base64,${screenshotBuffer.toString('base64')}`
    };
}