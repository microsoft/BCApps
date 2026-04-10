var addInContainer = 'controlAddIn';

var FlowIntegrationAddIn = function () {
  var flowSdk,
    hostName,
    accessToken,
    locale,

    resetContainer = function () {
      document.getElementById(addInContainer).innerHTML = '';
    },

    notifyError = function (error, description) {
      Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ErrorOccurred', [error, description]);
    },

    initialize = function (flowHostName, flowLocale, flowServiceToken) {
      hostName = flowHostName;
      locale = flowLocale;
      accessToken = flowServiceToken;

      try {
        flowSdk = new MsFlowSdk(
          {
            hostName: hostName,
            locale: locale
          });
      } catch (e) {
        notifyError(e.name, e.message);
      }
    },

    loadFlows = function (flowEnvironmentId) {
      resetContainer();

      var widgetOptions = {
        enableOnBehalfOfTokens: true,
        container: addInContainer,
        environmentId: flowEnvironmentId
      };

      try {
        var widget = flowSdk.renderWidget('flows', widgetOptions);
        widget.iframe.style.width = '100%';
        widget.iframe.style.height = '100%';
        widget.iframe.style.border = 'none';

        widget.callbacks.GET_ACCESS_TOKEN = function (requestParam, widgetDoneCallback) {
          widgetDoneCallback(
            null,
            {
              token: accessToken
            });

        };
      } catch (e) {
        notifyError(e.name, e.message);
      }
    },

    loadTemplates = function (flowEnvironmentId, searchTerm, pageSize, destination) {
      resetContainer();

      var widgetOptions = {
        enableOnBehalfOfTokens: true,
        container: addInContainer,
        environmentId: flowEnvironmentId,
        templatesSettings: {
          searchTerm: searchTerm,
          pageSize: pageSize,
          destination: destination,
          isManualFilter: true
        }
      };

      try {
        var widget = flowSdk.renderWidget('templates', widgetOptions);
        widget.iframe.style.width = '100%';
        widget.iframe.style.height = '100%';
        widget.iframe.style.border = 'none';

        widget.callbacks.GET_ACCESS_TOKEN = function (requestParam, widgetDoneCallback) {
          widgetDoneCallback(null,
            {
              token: accessToken
            });
        };
      } catch (e) {
        notifyError(e.name, e.message);
      }
    };

  return {
    initialize: initialize,
    loadFlows: loadFlows,
    loadTemplates: loadTemplates,
    notifyError: notifyError
  };

}();

function Initialize(flowHostName, locale, flowServiceToken) {
  try {
    if (typeof flowHostName !== 'string' || !flowHostName) throw 'Invalid Flow hostName.';
    if (typeof locale !== 'string') throw 'Invalid locale.';
    if (typeof flowServiceToken !== 'string' || !flowServiceToken) throw 'Invalid Flow Service Token.';
  } catch (e) {
    FlowIntegrationAddIn.notifyError(e.name, e.message);
  }

  FlowIntegrationAddIn.initialize(flowHostName, locale, flowServiceToken);
}

function LoadFlows(environmentId) {
  try {
    if (typeof environmentId !== 'string' || !environmentId) throw 'Invalid Environment Id.';
  } catch (e) {
    FlowIntegrationAddIn.notifyError(e.name, e.message);
  }
  FlowIntegrationAddIn.loadFlows(environmentId);
}

function LoadTemplates(environmentId, searchTerm, pageSize, destination) {
  try {
    if (typeof environmentId !== 'string' || !environmentId) throw 'Invalid Environment Id.';
    if (typeof searchTerm !== 'string') throw 'Invalid Search Term';
  } catch (e) {
    FlowIntegrationAddIn.notifyError(e.name, e.message);
  }

  if (typeof pageSize !== 'string' || !pageSize) pageSize = '8';
  if (typeof destination !== 'string' || !destination) destination = 'new';

  var escapedSearchTerm = encodeURIComponent(searchTerm);

  FlowIntegrationAddIn.loadTemplates(environmentId, escapedSearchTerm, pageSize, destination);
}
