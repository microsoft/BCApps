#if not EXT
namespace Microsoft.EServices.EDocumentConnector.ForNAV;
using System.Security.AccessControl;

permissionsetextension 6413 "ForNAV Peppol D365 Team Member" extends "D365 Team Member"
{
    IncludedPermissionSets = "ForNAV EDoc Inc Read";
}
#endif