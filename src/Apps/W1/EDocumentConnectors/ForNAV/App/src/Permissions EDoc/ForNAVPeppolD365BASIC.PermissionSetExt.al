namespace Microsoft.EServices.EDocumentConnector.ForNAV;
using System.Security.AccessControl;
permissionsetextension 6411 "ForNAV Peppol D365 BASIC" extends "D365 READ"
{
#pragma warning disable AA0052,AS0112
    IncludedPermissionSets = "ForNAV EDoc Edit";
}