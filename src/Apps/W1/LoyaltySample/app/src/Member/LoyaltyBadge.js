'use strict';

function RenderBadge(memberName, email, tier) {
    var container = document.getElementById('loyalty-badge');
    if (!container) {
        container = document.createElement('div');
        container.id = 'loyalty-badge';
        document.body.appendChild(container);
    }

    container.innerHTML = '<b>' + memberName + '</b> &lt;' + email + '&gt; - ' + tier;
    container.style.color = '#d73b02';
    container.style.backgroundColor = '#fff4ce';
    container.style.fontFamily = 'Segoe UI';
}

window.Microsoft = window.Microsoft || {};
window.Microsoft.Dynamics = window.Microsoft.Dynamics || {};
window.Microsoft.Dynamics.NAV = window.Microsoft.Dynamics.NAV || {};
window.Microsoft.Dynamics.NAV.InvokeMethod = window.Microsoft.Dynamics.NAV.InvokeMethod || function () { };

if (typeof Microsoft !== 'undefined' && Microsoft.Dynamics && Microsoft.Dynamics.NAV) {
    Microsoft.Dynamics.NAV.RenderBadge = RenderBadge;
}
