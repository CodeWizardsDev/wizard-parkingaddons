window.addEventListener('message', (event) => {
    const data = event.data;
    const ui = document.getElementById('reverse-sensor-ui');
    const f = document.getElementById('far');
    const m = document.getElementById('medium');
    const c = document.getElementById('close');
    const vc = document.getElementById('veryClose');

    if (data.action === 'show') {
        ui.style.display = 'flex';
    } else if (data.action === 'hide') {
        ui.style.display = 'none';
            f.style.backgroundColor = 'rgba(116, 116, 116, 0.4)';
            m.style.backgroundColor = 'rgba(116, 116, 116, 0.4)';
            c.style.backgroundColor = 'rgba(116, 116, 116, 0.4)';
            vc.style.backgroundColor = 'rgba(116, 116, 116, 0.4)';
    } else if (data.action === 'update') {
            f.style.backgroundColor = 'rgba(116, 116, 116, 0.4)';
            m.style.backgroundColor = 'rgba(116, 116, 116, 0.4)';
            c.style.backgroundColor = 'rgba(116, 116, 116, 0.4)';
            vc.style.backgroundColor = 'rgba(116, 116, 116, 0.4)';

        switch (data.line) {
            case 'far':
                f.style.backgroundColor = 'green';
                break;
            case 'medium':
                f.style.backgroundColor = 'green';
                m.style.backgroundColor = 'yellow';
                break;
            case 'close':
                f.style.backgroundColor = 'green';
                m.style.backgroundColor = 'yellow';
                c.style.backgroundColor = 'darkorange';
                break;
            case 'veryClose':
                f.style.backgroundColor = 'green';
                m.style.backgroundColor = 'yellow';
                c.style.backgroundColor = 'darkorange';
                vc.style.backgroundColor = 'red';
                break;
            default:
                f.style.backgroundColor = 'rgba(116, 116, 116, 0.4)';
                m.style.backgroundColor = 'rgba(116, 116, 116, 0.4)';
                c.style.backgroundColor = 'rgba(116, 116, 116, 0.4)';
                vc.style.backgroundColor = 'rgba(116, 116, 116, 0.4)';
                break;
        }
    }
});
