// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

dotnet
{
    assembly("Microsoft.Dynamics.Nav.EwsWrapper.ALTestHelper")
    {
        type("Microsoft.Dynamics.Nav.Exchange.ALTest.EmailAddress"; "Microsoft.Dynamics.Nav.Exchange.ALTest.EmailAddress")
        {
        }

        type("Microsoft.Dynamics.Nav.Exchange.ALTest.EmailFolder"; "Microsoft.Dynamics.Nav.Exchange.ALTest.EmailFolder")
        {
        }

        type("Microsoft.Dynamics.Nav.Exchange.ALTest.EmailMessage"; "Microsoft.Dynamics.Nav.Exchange.ALTest.EmailMessage")
        {
        }

        type("Microsoft.Dynamics.Nav.Exchange.Attachment"; "Microsoft.Dynamics.Nav.Exchange.Attachment")
        {
        }
    }
}

