// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.BatchProcessing;

permissionset 1380 "Batch Processing - Objects"
{
    Access = Internal;
    Assignable = false;

    Permissions = table "Batch Processing Artifact" = X,
                  table "Batch Processing Parameter" = X,
                  table "Batch Processing Session Map" = X,
                  //codeunit "Batch Posting Print Mgt." = X,
                  codeunit "Batch Processing Mgt." = X,
                  codeunit "Batch Processing Mgt. Handler" = X;
}