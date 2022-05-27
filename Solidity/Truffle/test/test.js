const Hello = artifacts.require("Hello");

contract ('Hello', accounts => {

    it('Obtener nombre', async () => {

        let instance = await Hello.deployed();

        const msg = await instance.getMessage().call({from: accounts[0]});

        assert.equal(msg, 'hola mundo');
    });

    it('Cambiar nombre', async () => {

        let instance = await Hello.deployed();

        const tx = await instance.setMessage('Chiao', {from: accounts[4]});

        console.log(tx);

        const msg = await instance.getMessage().call();

        assert.equal(msg, 'Chiao');
    });
});