namespace System.Security.AccessControl;

using Microsoft.EServices.EDocument;

permissionsetextension 7000002 "SII LOCAL READ" extends "LOCAL READ"
{
    Permissions =
                  tabledata "SII Doc. Upload State" = R,
                  tabledata "SII History" = R,
                  tabledata "SII Purch. Doc. Scheme Code" = R,
                  tabledata "SII Sales Document Scheme Code" = R,
                  tabledata "SII Missing Entries State" = R,
                  tabledata "SII Session" = R,
                  tabledata "SII Setup" = R,
                  tabledata "SII Sending State" = R;
}