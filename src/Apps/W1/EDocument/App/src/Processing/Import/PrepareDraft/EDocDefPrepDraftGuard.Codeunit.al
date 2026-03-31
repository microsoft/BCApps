// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument.Processing.Interfaces;

codeunit 6243 "E-Doc. Def. Prep. Draft Guard" implements IPrepareDraftGuard
{
    Access = Internal;

    procedure SkipPrepareDraft(): Boolean
    begin
        exit(false);
    end;
}
