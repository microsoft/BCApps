// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.eServices.EDocument.IO.Peppol;
using Microsoft.EServices.EDocument.OrderMatch;
#if not CLEAN29
using Microsoft.eServices.EDocument.OrderMatch.Copilot;
#endif
using Microsoft.eServices.EDocument.Processing;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.EServices.EDocument.Processing.Import.Sales;
using Microsoft.eServices.EDocument.Processing.Message;
using Microsoft.eServices.EDocument.Service.Participant;

permissionset 6101 "E-Doc. Core - Read"
{
    Access = Public;
    Assignable = true;
    Caption = 'E-Document - Read';

    IncludedPermissionSets = "E-Doc. Core - Objects";

    Permissions =
        tabledata "E-Document" = R,
    #region Mapping
        tabledata "E-Doc. Mapping" = R,
        tabledata "E-Doc. Mapping Log" = R,
    #endregion Mapping
    #region Logging
        tabledata "E-Document Log" = R,
        tabledata "E-Doc. Data Storage" = R,
        tabledata "E-Document Service Status" = R,
        tabledata "E-Document Integration Log" = R,
        tabledata "E-Document Message" = R,
    #endregion Logging
        tabledata "E-Doc. Imported Line" = R,
        tabledata "E-Doc. Order Match" = R,
#if not CLEAN29
        tabledata "E-Doc. PO Match Prop. Buffer" = R,
#endif
    #region Service
        tabledata "E-Document Service" = R,
        tabledata "E-Doc. Service Data Exch. Def." = R,
        tabledata "E-Doc. Service Supported Type" = R,
        tabledata "Service Participant" = R,
    #endregion Service
    #region Purchase draft
        tabledata "E-Doc. Import Parameters" = R,
        tabledata "E-Document Purchase Header" = R,
        tabledata "E-Document Purchase Line" = R,
        tabledata "E-Document Line - Field" = R,
        tabledata "E-Doc. Vendor Assign. History" = R,
        tabledata "E-Doc. Purchase Line History" = R,
        tabledata "ED Purchase Line Field Setup" = R,
        tabledata "E-Doc Sample Purch. Inv File" = R,
#if not CLEAN28
#pragma warning disable AL0432
        tabledata "EDoc Historical Matching Setup" = R,
#pragma warning restore AL0432
#endif
        tabledata "E-Doc. Record Link" = R,
    #endregion Purchase draft
    #region Sales draft
        tabledata "E-Document Sales Header" = R,
        tabledata "E-Document Sales Line" = R;
    #endregion Sales draft
}
