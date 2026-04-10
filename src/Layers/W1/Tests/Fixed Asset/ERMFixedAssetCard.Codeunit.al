codeunit 134456 "ERM Fixed Asset Card"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Fixed Asset] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        FoundFALedgerEntriesErr: Label 'You cannot change the FA posting group because posted FA ledger entries use the existing posting group.';
        FAPostingGroupChangeDeniedTxt: Label 'The current FA posting group is %1 but the FA subclass %2 has the default FA posting group %3. \Because there are posted FA ledger entries we will not change the FA posting group.';
        FAPostingGroupChangeConfirmTxt: Label 'The current FA posting group is %1, but the FA subclass %2 has the default FA posting group %3. \Do you want to update the FA posting group?';

    [Test]
    [Scope('OnPrem')]
    procedure TestFACardSaveSimpleBookOnClose()
    var
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubclass: Record "FA Subclass";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FixedAssetCard: TestPage "Fixed Asset Card";
        Description: Text[100];
    begin
        // [FEATURE] [Posting Group]
        // [SCENARIO 337570] System assigns "Default FA Posting Group" from "FA Sub Class" to newly created Fixed Asset

        // [GIVEN] FA Setup is in place
        FixedAsset.DeleteAll();
        CreateRelatedFAClassFASubclassFAPostingGroup(FAClass, FASubclass, FAPostingGroup);
        Description := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(FixedAsset.Description)), 1, MaxStrLen(FixedAsset.Description));

        // [WHEN] Fixed Asset Card filled out and closed
        FixedAssetCard.OpenNew();
        FixedAssetCard.Description.SetValue(Description);
        FixedAssetCard."FA Subclass Code".SetValue(FASubclass.Code);
        FixedAssetCard.Close();

        // [THEN] The Fixed Asset Can be read again
        FixedAssetCard.OpenView();
        FixedAssetCard.Description.AssertEquals(Description);
        FixedAssetCard."FA Subclass Code".SetValue(FASubclass.Code);
        FixedAssetCard.FAPostingGroup.AssertEquals(FAPostingGroup.Code); // FA Posting Group of FA Depreciation Book
        FASetup.Get();
        FixedAssetCard.DepreciationBookCode.AssertEquals(FASetup."Default Depr. Book");
        FixedAssetCard.FAPostingGroup.AssertEquals(FAPostingGroup.Code);
        FixedAssetCard.Close();

        // [THEN] "FA"."FA Posting Group" = FASubClass."Default FA Posting Group"
        FixedAsset.FindFirst();
        FixedAsset.TestField("FA Posting Group", FAPostingGroup.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFACardSaveSimpleBookOnValidate()
    var
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubclass: Record "FA Subclass";
        FAPostingGroup: Record "FA Posting Group";
        FAPostingGroup2: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAssetCard: TestPage "Fixed Asset Card";
        StartingDate: Date;
        EndingDate: Date;
        NoDepreciationYears: Integer;
    begin
        // [GIVEN] FA Setup in place, and a fixed asset with a default depreciation book
        FixedAsset.DeleteAll();
        CreateFAWithClassPostingGroupAndSubclass(FAPostingGroup, FAClass, FASubclass, FixedAsset);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup2);
        FASetup.Get();
        CreateFADepreciationBookEmpty(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book", FAPostingGroup.Code);

        FADepreciationBook.Reset();
        FADepreciationBook.Get(FixedAsset."No.", FASetup."Default Depr. Book");

        // [WHEN] Fixed Asset Card is loaded and the Depreciation Book fields are modified
        FixedAssetCard.OpenEdit();
        FixedAssetCard.GotoRecord(FixedAsset);
        FixedAssetCard.DepreciationBookCode.AssertEquals(FASetup."Default Depr. Book");

        // [THEN] The Depreciation Book retains the modified values after the Fixed Asset is reloaded
        FixedAssetCard.FAPostingGroup.SetValue(FAPostingGroup2.Code);
        FADepreciationBook.Get(FixedAsset."No.", FASetup."Default Depr. Book");
        FADepreciationBook.TestField("FA Posting Group", FAPostingGroup2.Code);

        FixedAssetCard.DepreciationMethod.SetValue(FADepreciationBook."Depreciation Method"::"Straight-Line");
        FADepreciationBook.Get(FixedAsset."No.", FASetup."Default Depr. Book");
        FADepreciationBook.TestField("Depreciation Method", FADepreciationBook."Depreciation Method"::"Straight-Line");

        StartingDate := WorkDate() - 1;
        FixedAssetCard.DepreciationStartingDate.SetValue(StartingDate);
        FADepreciationBook.Get(FixedAsset."No.", FASetup."Default Depr. Book");
        FADepreciationBook.TestField("Depreciation Starting Date", StartingDate);

        NoDepreciationYears := LibraryRandom.RandIntInRange(1, 20);
        FixedAssetCard.NumberOfDepreciationYears.SetValue(NoDepreciationYears);
        FADepreciationBook.Get(FixedAsset."No.", FASetup."Default Depr. Book");
        FADepreciationBook.TestField("No. of Depreciation Years", NoDepreciationYears);

        EndingDate := WorkDate() + 1;
        FixedAssetCard.DepreciationEndingDate.SetValue(EndingDate);
        FADepreciationBook.Get(FixedAsset."No.", FASetup."Default Depr. Book");
        FADepreciationBook.TestField("Depreciation Ending Date", EndingDate);

        FixedAssetCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFACardSaveSimpleBookOnNextPrev()
    var
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubclass: Record "FA Subclass";
        FAPostingGroup: Record "FA Posting Group";
        FAPostingGroup2: Record "FA Posting Group";
        FixedAssetCard: TestPage "Fixed Asset Card";
        Description: Text[100];
    begin
        // [GIVEN] FA Setup is in place
        FixedAsset.DeleteAll();
        CreateRelatedFAClassFASubclassFAPostingGroup(FAClass, FASubclass, FAPostingGroup);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup2);
        Description := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(FixedAsset.Description)), 1, MaxStrLen(FixedAsset.Description));

        // [WHEN] Fixed Asset Card filed out and closed
        FixedAssetCard.OpenNew();
        FixedAssetCard.Description.SetValue(Description);
        FixedAssetCard."FA Subclass Code".SetValue(FASubclass.Code);
        FixedAssetCard.Close();

        // [WHEN] Fixed Asset Card filed out with asset 2 and record is moved to first asset
        FixedAssetCard.OpenNew();
        FixedAssetCard.Description.SetValue(Description);
        FixedAssetCard."FA Subclass Code".SetValue(FASubclass.Code);
        FixedAssetCard.FAPostingGroup.SetValue(FAPostingGroup2.Code);
        FixedAssetCard.Previous();

        // [THEN] Fixed asset is saved as expected
        FixedAssetCard.FAPostingGroup.AssertEquals(FAPostingGroup.Code);
        FixedAssetCard.Next();
        FixedAssetCard.FAPostingGroup.AssertEquals(FAPostingGroup2.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFACardSaveSimpleBookOnChangetoMultibook()
    var
        FASetup: Record "FA Setup";
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubclass: Record "FA Subclass";
        FAPostingGroup: Record "FA Posting Group";
        FixedAssetCard: TestPage "Fixed Asset Card";
        Description: Text[100];
    begin
        // [GIVEN] FA Setup is in place
        FixedAsset.DeleteAll();
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        CreateRelatedFAClassFASubclassFAPostingGroup(FAClass, FASubclass, FAPostingGroup);
        Description := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(FixedAsset.Description)), 1, MaxStrLen(FixedAsset.Description));

        // [WHEN] Fixed Asset create with 2 books
        FixedAssetCard.OpenNew();
        FixedAssetCard.Description.SetValue(Description);
        FixedAssetCard."FA Subclass Code".SetValue(FASubclass.Code);
        FixedAssetCard.AddMoreDeprBooks.DrillDown();
        FASetup.Get();
        FixedAssetCard.DepreciationBook."Depreciation Book Code".AssertEquals(FASetup."Default Depr. Book");
        FixedAssetCard.DepreciationBook."FA Posting Group".AssertEquals(FAPostingGroup.Code);
        FixedAssetCard.DepreciationBook.New();
        FixedAssetCard.DepreciationBook."Depreciation Book Code".SetValue(DepreciationBook.Code);
        FixedAssetCard.DepreciationBook."FA Posting Group".SetValue(FAPostingGroup.Code);
        FixedAssetCard.Close();

        // [THEN] both books can be viewd in the card
        FixedAssetCard.OpenView();
        FixedAssetCard.DepreciationBook.GotoKey(FixedAssetCard."No.".Value, FASetup."Default Depr. Book");
        FixedAssetCard.DepreciationBook."FA Posting Group".AssertEquals(FAPostingGroup.Code);
        FixedAssetCard.DepreciationBook.GotoKey(FixedAssetCard."No.".Value, DepreciationBook.Code);
        FixedAssetCard.DepreciationBook."FA Posting Group".AssertEquals(FAPostingGroup.Code);
        FixedAssetCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFACardMultibookIsOnlyAccessibleAfterFirstBookCreation()
    var
        FixedAsset: Record "Fixed Asset";
        FASubclass: Record "FA Subclass";
        FixedAssetCard: TestPage "Fixed Asset Card";
        Description: Text[100];
    begin
        // [GIVEN] FA Setup is in place
        FixedAssetAndDeprecationBookSetup(FASubclass);
        Description := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(FixedAsset.Description)), 1, MaxStrLen(FixedAsset.Description));

        // [WHEN] Fixed Asset is created
        FixedAssetCard.OpenNew();
        FixedAssetCard.Description.SetValue(Description);

        // [THEN] AddMoreDeprBooks is not visible until at least one book is created
        Assert.IsFalse(FixedAssetCard.AddMoreDeprBooks.Visible(), 'AddMoreDeprBooks has to be invisible.');
        FixedAssetCard."FA Subclass Code".SetValue(FASubclass.Code);
        Assert.IsTrue(FixedAssetCard.AddMoreDeprBooks.Visible(), 'AddMoreDeprBooks has to be visible');
        FixedAssetCard.Close();

        FixedAssetCard.OpenView();
        Assert.IsTrue(FixedAssetCard.AddMoreDeprBooks.Visible(), 'AddMoreDeprBooks has to be visible');
        FixedAssetCard.Close();
    end;

    [Test]
    [HandlerFunctions('FASubclassValidationHandler')]
    [Scope('OnPrem')]
    procedure TestFACardSubclassRestrictedByClass()
    var
        FASubclassWithNoClass: Record "FA Subclass";
        FAClass1: Record "FA Class";
        FASubclassWithFAClass1Parrent: Record "FA Subclass";
        FAClass2: Record "FA Class";
        FASubclassWithFAClass2Parrent: Record "FA Subclass";
        FixedAssetCard: TestPage "Fixed Asset Card";
    begin
        // [GIVEN] FA Setup is in place
        LibraryFixedAsset.CreateFASubclass(FASubclassWithNoClass);
        LibraryFixedAsset.CreateFAClass(FAClass1);
        LibraryFixedAsset.CreateFASubclassDetailed(FASubclassWithFAClass1Parrent, FAClass1.Code, '');
        LibraryFixedAsset.CreateFAClass(FAClass2);
        LibraryFixedAsset.CreateFASubclassDetailed(FASubclassWithFAClass2Parrent, FAClass2.Code, '');

        // [GIVEN] FAClass1.Code set
        FixedAssetCard.OpenNew();
        FixedAssetCard."FA Class Code".Value := FAClass1.Code;
        LibraryVariableStorage.Enqueue(FASubclassWithNoClass.Code);
        LibraryVariableStorage.Enqueue(FASubclassWithFAClass1Parrent.Code);
        LibraryVariableStorage.Enqueue(FASubclassWithFAClass2Parrent.Code);
        // Validation handler in FASubclassValidationHandler
        // [WHEN] SubClass lookup is invoked
        // [THEN] All but Subclass2 can be found in the lookup
        FixedAssetCard."FA Subclass Code".Lookup();
        FixedAssetCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFACardSimpleBookDisposedValue()
    var
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubclass: Record "FA Subclass";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAssetCard: TestPage "Fixed Asset Card";
        FALedgerEntriesList: TestPage "FA Ledger Entries";
        BookValue: Decimal;
    begin
        // [GIVEN] FA Setup in place, and a disposed fixed asset with a default depreciation book with Amount "A"
        FixedAsset.DeleteAll();
        CreateFAWithClassPostingGroupAndSubclass(FAPostingGroup, FAClass, FASubclass, FixedAsset);
        FASetup.Get();
        BookValue := LibraryRandom.RandDecInRange(10, 1000, 0);
        CreateFADepreciationBookWithValue(
          FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book", FAPostingGroup.Code, BookValue);
        DisposeFADepreciationBook(FADepreciationBook, BookValue);

        // [WHEN] Fixed Asset Card is loaded
        FixedAssetCard.OpenEdit();
        FixedAssetCard.GotoRecord(FixedAsset);

        // [THEN] The Depreciation Book value equals 0
        FixedAssetCard.DepreciationBookCode.AssertEquals(FASetup."Default Depr. Book");
        FixedAssetCard.BookValue.AssertEquals(0);

        // [WHEN] Drill Down on "Book Value"
        FALedgerEntriesList.Trap();
        FixedAssetCard.BookValue.DrillDown();
        // [THEN] Page "FA Ledger Entries" showing 1 entries, where total "Amount" is equal to "A"
        FALedgerEntriesList.First();
        FALedgerEntriesList.Amount.AssertEquals(BookValue);
        FALedgerEntriesList.Close();
        FixedAssetCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure EnableSaaSNotificationPreferenceSetupOnInitializingNotificationWithDefaultState()
    var
        FixedAsset: Record "Fixed Asset";
        MyNotifications: Record "My Notifications";
        LibraryPermissions: Codeunit "Library - Permissions";
        MyNotificationsPage: TestPage "My Notifications";
    begin
        // [GIVEN] A user
        LibraryPermissions.CreateWindowsUserSecurityID(UserId);

        // [WHEN] My Notifications Page is opened
        MyNotificationsPage.OpenView();

        // [THEN] A notification entry is added to MyNotification for the current user
        MyNotifications.Get(UserId, FixedAsset.GetNotificationID());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPictureFactboxExist()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAssetCard: TestPage "Fixed Asset Card";
    begin
        // [Feature] [Fixed Asset]
        // [SCENARIO 210139] Picture Factbox exists on a Fixed Asset Card.

        // [GIVEN] Fixed Asset "FA".
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);

        // [WHEN] Fixed Asset Card page is opened for "FA"
        FixedAssetCard.OpenEdit();
        FixedAssetCard.GotoRecord(FixedAsset);

        // [THEN] Picture Factbox is existing on a Fixed Asset Card page.
        Assert.IsTrue(
          FixedAssetCard.FixedAssetPicture.ImportPicture.Visible(),
          'Picture Factbox with Import Picture button is expected');

        Assert.IsTrue(
          FixedAssetCard.FixedAssetPicture.Image.Visible(),
          'Picture Factbox with image area is expected');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFACardMultibookDecliningBalancePercentIsVisible()
    var
        FixedAsset: Record "Fixed Asset";
        FASubclass: Record "FA Subclass";
        FixedAssetCard: TestPage "Fixed Asset Card";
        Description: Text[100];
    begin
        // [Feature] [UT]
        // [SCENARIO 234906] Declining Balance % is visible on a Fixed Asset Card.

        // [GIVEN] FA Setup is in place
        FixedAssetAndDeprecationBookSetup(FASubclass);
        Description := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(FixedAsset.Description)), 1, MaxStrLen(FixedAsset.Description));

        // [GIVEN] Fixed Asset is created from Card
        FixedAssetCard.OpenNew();
        FixedAssetCard.Description.SetValue(Description);
        FixedAssetCard."FA Subclass Code".SetValue(FASubclass.Code);

        // [WHEN] Open FA Depreciation Books Subform
        FixedAssetCard.AddMoreDeprBooks.DrillDown();

        // [THEN] "Declining-Balance %" is visible and editable
        Assert.IsTrue(FixedAssetCard.DepreciationBook."Declining-Balance %".Visible(), 'Declining-Balance % has to be visible');
        Assert.IsTrue(FixedAssetCard.DepreciationBook."Declining-Balance %".Editable(), 'Declining-Balance % has to be editable');

        FixedAssetCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FACardSimpleBookValueUndisposed()
    var
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubclass: Record "FA Subclass";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAssetCard: TestPage "Fixed Asset Card";
        FALedgerEntriesList: TestPage "FA Ledger Entries";
        BookValue: Decimal;
    begin
        // [SCENARIO 281772] Book Value of an undisposed Fixed Asset is shown on "Fixed Asset Card" Simple View

        // [GIVEN] FA Setup with Fixed Asset
        FixedAsset.DeleteAll();
        CreateFAWithClassPostingGroupAndSubclass(FAPostingGroup, FAClass, FASubclass, FixedAsset);
        FASetup.Get();

        // [GIVEN] Default Depreciation Book created for Fixed Asset with Book Value = 500
        BookValue := LibraryRandom.RandDecInRange(10, 1000, 0);
        CreateFADepreciationBookWithValue(
          FADepreciationBook,
          FixedAsset."No.",
          FASetup."Default Depr. Book",
          FAPostingGroup.Code,
          BookValue);

        // [WHEN] Fixed Asset Card is loaded
        FixedAssetCard.OpenEdit();
        FixedAssetCard.FILTER.SetFilter("No.", FixedAsset."No.");

        // [THEN] The Depreciation Book value equals 500
        ValidateBookValueSimple(FixedAssetCard, FASetup."Default Depr. Book", BookValue);

        // [WHEN] Drill Down on "Book Value"
        FALedgerEntriesList.Trap();
        FixedAssetCard.BookValue.DrillDown();
        // [THEN] Page "FA Ledger Entries" showing entry, where "Amount" is 500
        FALedgerEntriesList.First();
        FALedgerEntriesList.Amount.AssertEquals(BookValue);
        FALedgerEntriesList.Close();
        FixedAssetCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FACardMultibookDisposedValue()
    var
        FixedAsset: Record "Fixed Asset";
        FASetup: Record "FA Setup";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        FASubclass: Record "FA Subclass";
        FAClass: Record "FA Class";
        FixedAssetCard: TestPage "Fixed Asset Card";
    begin
        // [SCENARIO 281772] Book Value of a disposed Fixed Asset is 0 on FA Depreciation Books Subform

        // [GIVEN] FA Setup with Fixed Asset
        FixedAsset.DeleteAll();
        CreateFAWithClassPostingGroupAndSubclass(FAPostingGroup, FAClass, FASubclass, FixedAsset);
        FASetup.Get();

        // [GIVEN] Default Depreciation Book created for Fixed Asset
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book", FAPostingGroup.Code);

        // [GIVEN] Fixed Asset Disposed
        FADepreciationBook."Disposal Date" := WorkDate();
        FADepreciationBook.Modify(true);

        // [GIVEN] Fixed Asset Card is loaded
        FixedAssetCard.OpenEdit();
        FixedAssetCard.FILTER.SetFilter("No.", FixedAsset."No.");

        // [WHEN] FA Depreciation Books Subform is opened
        FixedAssetCard.AddMoreDeprBooks.DrillDown();

        // [THEN] Book Value of the disposed Fixed Asset equals 0
        FixedAssetCard.DepreciationBook."Depreciation Book Code".AssertEquals(FASetup."Default Depr. Book");
        FixedAssetCard.DepreciationBook.BookValue.AssertEquals(0);

        FixedAssetCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FACardMultibookBookValueUndisposed()
    var
        FixedAsset: Record "Fixed Asset";
        FASetup: Record "FA Setup";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        FASubclass: Record "FA Subclass";
        FAClass: Record "FA Class";
        FixedAssetCard: TestPage "Fixed Asset Card";
        BookValue: Decimal;
    begin
        // [SCENARIO 281772] Book Value of an undisposed Fixed Asset is shown on FA Depreciation Books Subform

        // [GIVEN] FA Setup with Fixed Asset
        FixedAsset.DeleteAll();
        CreateFAWithClassPostingGroupAndSubclass(FAPostingGroup, FAClass, FASubclass, FixedAsset);
        FASetup.Get();

        // [GIVEN] Default Depreciation Book created for Fixed Asset with Book Value = 500
        BookValue := LibraryRandom.RandDecInRange(10, 1000, 0);
        CreateFADepreciationBookWithValue(
          FADepreciationBook,
          FixedAsset."No.",
          FASetup."Default Depr. Book",
          FAPostingGroup.Code,
          BookValue);

        // [GIVEN] Fixed Asset Card is loaded
        FixedAssetCard.OpenEdit();
        FixedAssetCard.FILTER.SetFilter("No.", FixedAsset."No.");

        // [WHEN] FA Depreciation Books Subform is opened
        FixedAssetCard.AddMoreDeprBooks.DrillDown();

        // [THEN] Book Value of the Fixed Asset equals 500
        ValidateBookValueMultibook(FixedAssetCard, FASetup."Default Depr. Book", BookValue);

        FixedAssetCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FACardDepreciationTableCode()
    var
        FixedAsset: Record "Fixed Asset";
        FASetup: Record "FA Setup";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        FASubclass: Record "FA Subclass";
        FAClass: Record "FA Class";
        DepreciationTableHeader: Record "Depreciation Table Header";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        FixedAssetCard: TestPage "Fixed Asset Card";
    begin
        // [SCENARIO 283323] User is able to setup Depreciation Table Code on the FA Card page

        // [GIVEN] Activate application area #FixedAsset
        LibraryApplicationArea.EnableFixedAssetsSetup();

        // [GIVEN] FA Setup with Fixed Asset
        FixedAsset.DeleteAll();
        CreateFAWithClassPostingGroupAndSubclass(FAPostingGroup, FAClass, FASubclass, FixedAsset);
        FASetup.Get();
        CreateFADepreciationBookEmpty(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book", FAPostingGroup.Code);
        FADepreciationBook.Validate("Depreciation Method", FADepreciationBook."Depreciation Method"::"User-Defined");
        FADepreciationBook.Modify(true);

        // [GIVEN] Create new Depreciation Table Code "DTC"
        LibraryFixedAsset.CreateDepreciationTableHeader(DepreciationTableHeader);

        // [GIVEN] Open FA Card page
        FixedAssetCard.OpenEdit();
        FixedAssetCard.FILTER.SetFilter("No.", FixedAsset."No.");

        // [WHEN] Depreciation Table Code control is being set to "DTC"
        FixedAssetCard.DepreciationTableCode.SetValue(DepreciationTableHeader.Code);
        FixedAssetCard.OK().Invoke();

        // [THEN] FADepreciationBook."Depreciation Table Code" = "DTC"
        FADepreciationBook.Find();
        FADepreciationBook.TestField("Depreciation Table Code", DepreciationTableHeader.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FACardUseHalfYearConvention()
    var
        FixedAsset: Record "Fixed Asset";
        FASetup: Record "FA Setup";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        FASubclass: Record "FA Subclass";
        FAClass: Record "FA Class";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        FixedAssetCard: TestPage "Fixed Asset Card";
    begin
        // [SCENARIO 283323] User is able to setup Use Half-Year Convention on the FA Card page

        // [GIVEN] Activate application area #FixedAsset
        LibraryApplicationArea.EnableFixedAssetsSetup();

        // [GIVEN] FA Setup with Fixed Asset
        FixedAsset.DeleteAll();
        CreateFAWithClassPostingGroupAndSubclass(FAPostingGroup, FAClass, FASubclass, FixedAsset);
        FASetup.Get();
        CreateFADepreciationBookEmpty(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book", FAPostingGroup.Code);

        // [GIVEN] Open FA Card page
        FixedAssetCard.OpenEdit();
        FixedAssetCard.FILTER.SetFilter("No.", FixedAsset."No.");

        // [WHEN] Use Half-Year Convention control is being set to TRUE
        FixedAssetCard.UseHalfYearConvention.SetValue(true);
        FixedAssetCard.OK().Invoke();

        // [THEN] FADepreciationBook."Use Half-Year Convention" = TRUE
        FADepreciationBook.Find();
        FADepreciationBook.TestField("Use Half-Year Convention", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFACardBookValueDrillDown()
    var
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubclass: Record "FA Subclass";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        FixedAssetCard: TestPage "Fixed Asset Card";
        FALedgerEntriesList: TestPage "FA Ledger Entries";
        BookValue: Decimal;
    begin
        // [FEATURE] [Disposal] [Book Value]
        // [SCENARIO 283324] Create FA document and disposed it. As a result should be 2 FA Ledger Entries Line.
        // [SCENARIO 386725] Create FA document and disposed it. When you drill down on Fixed Asset card page all 3 relevant entries must be shown.

        // [GIVEN] FA Setup in place, and a disposed fixed asset with a default depreciation book and Amount = "A"
        CreateFAWithClassPostingGroupAndSubclass(FAPostingGroup, FAClass, FASubclass, FixedAsset);
        FASetup.Get();
        BookValue := LibraryRandom.RandDecInRange(10, 1000, 2);
        CreateFADepreciationBookWithValue(
          FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book", FAPostingGroup.Code, BookValue);
        DisposeFADepreciationBook(FADepreciationBook, BookValue);

        // [WHEN] Fixed Asset Card is loaded and Drill Down on "Book Value"
        FixedAssetCard.OpenEdit();
        FixedAssetCard.FILTER.SetFilter("No.", FixedAsset."No.");
        FALedgerEntriesList.Trap();
        FixedAssetCard.BookValue.DrillDown();

        // [THEN] Page "FA Ledger Entries" has 3 lines.
        // [THEN] First is acquisition Line and there are two more
        FALedgerEntriesList.First();
        Assert.AreEqual(FALedgerEntriesList.Amount.Value, Format(BookValue), 'FA doc.');
        Assert.AreEqual(
          Format(FALedgerEntry."FA Posting Type"::"Acquisition Cost"),
          FALedgerEntriesList."FA Posting Type".Value,
          FALedgerEntry.FieldCaption("FA Posting Type"));
        Assert.AreEqual(
          Format(FALedgerEntry."FA Posting Category"::" "),
          FALedgerEntriesList."FA Posting Category".Value,
          FALedgerEntry.FieldCaption("FA Posting Category"));

        // [THEN] There are 3 records total shown
        Assert.IsTrue(FALedgerEntriesList.Next(), 'There must be a second record shown');
        Assert.IsTrue(FALedgerEntriesList.Next(), 'There must be a third record shown');
        Assert.IsFalse(FALedgerEntriesList.Next(), 'No more records must be shown');

        FALedgerEntriesList.Close();
        FixedAssetCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFACardBookDisposalValue()
    var
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubclass: Record "FA Subclass";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FADepreciationBook: Record "FA Depreciation Book";
        DummyFALedgerEntry: Record "FA Ledger Entry";
        FixedAssetStatistics: TestPage "Fixed Asset Statistics";
        FixedAssetCard: TestPage "Fixed Asset Card";
        DisposalValue: Decimal;
    begin
        // [FEATURE] [Disposal] [Disposal Value]
        // [SCENARIO 319366] Create FA document and disposed it. As a result Disposal Value in FA Statistics page must be calculated.
        // [GIVEN] FA Setup in place, and a disposed fixed asset with
        // [GIVEN] FA Posting Type = Book Value on Disposal and "Book Value on Disposal" = "X"
        CreateFAWithClassPostingGroupAndSubclass(FAPostingGroup, FAClass, FASubclass, FixedAsset);
        FASetup.Get();
        DisposalValue := LibraryRandom.RandDecInRange(10, 1000, 2);
        CreateFADepreciationBookWithValue(
          FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book", FAPostingGroup.Code, DisposalValue);
        MockFALedgerEntryDisposal(
          FADepreciationBook."FA No.",
          FADepreciationBook."Depreciation Book Code",
          WorkDate(), -DisposalValue,
          DummyFALedgerEntry."FA Posting Type"::"Book Value on Disposal");

        // [WHEN] Fixed Asset Statistics."Book Value on Disposal" is calculated. Page FixedAssetStatistics is opened.
        FADepreciationBook.CalcFields("Book Value on Disposal");
        FixedAssetCard.OpenEdit();
        FixedAssetCard.FILTER.SetFilter("No.", FixedAsset."No.");
        FixedAssetStatistics.Trap();
        FixedAssetCard.Statistics.Invoke();

        // [THEN] "Book Value after Disposal" = "X" on FA Statistics Page
        FixedAssetStatistics.DisposalValue.AssertEquals(DisposalValue);
        FixedAssetCard.Close();
        FixedAssetStatistics.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestFACardChangeFASubclassWithAllowChangesInDeprField()
    var
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubclass: array[2] of Record "FA Subclass";
        FAPostingGroup: array[2] of Record "FA Posting Group";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FASetup: Record "FA Setup";
        FixedAssetCard: TestPage "Fixed Asset Card";
    begin
        // [FEATURE] [Posting Group]
        // [SCENARIO 329116] Create FA document and edit FA Subclass in it. The FA Posting Group is changed.

        // [GIVEN] 3 different FAPostingGroup were created, 3 different FASubclass were created, FAClass and DepreciationBook were created
        CreateFAClassWithTwoDetailedSubclasses(FAClass, FASubclass, FAPostingGroup);

        // [GIVEN] FixedAsset was created with "FA Subclass Code" and "FA Posting Group" equal first's variants.
        CreateFAWithClassAndSubclass(FixedAsset, FAClass.Code, FASubclass[1].Code);

        // [GIVEN] FA Depreciation Book was created with first variant of FA Posting Group.
        FASetup.Get();
        CreateFADepreciationBookEmpty(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book", FAPostingGroup[1].Code);

        // [GIVEN] Field "Allow Changes in Depr. Fields" in  table DepreciationBook =TRUE
        CreateDepreciationBookWithAllowChangesInDeprField(DepreciationBook, true);

        // [WHEN] FA Subclass change in FixedAssetCard to second variant
        FixedAssetCard.OpenEdit();
        FixedAssetCard.FILTER.SetFilter("No.", FixedAsset."No.");
        FixedAssetCard."FA Subclass Code".SetValue(FASubclass[2].Code);
        FixedAssetCard.OK().Invoke();

        // [THEN] The FA Subclass Code was changed, FADepreciationBook."FA Posting Group" is changed
        FixedAsset.Find();
        FADepreciationBook.Find();
        FixedAsset.TestField("FA Subclass Code", FASubclass[2].Code);
        FADepreciationBook.TestField("FA Posting Group", FAPostingGroup[2].Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestFACardChangeFASubclassWithoutAllowChangesInDeprField()
    var
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubclass: array[2] of Record "FA Subclass";
        FAPostingGroup: array[2] of Record "FA Posting Group";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FASetup: Record "FA Setup";
        FixedAssetCard: TestPage "Fixed Asset Card";
    begin
        // [FEATURE] [Posting Group]
        // [SCENARIO 329116] Create FA document and edit FA Subclass in it. The FA Posting Group is changed.

        // [GIVEN] 3 different FAPostingGroup were created, 3 different FASubclass were created, FAClass and DepreciationBook were created
        CreateFAClassWithTwoDetailedSubclasses(FAClass, FASubclass, FAPostingGroup);

        // [GIVEN] FixedAsset was created with "FA Subclass Code" and "FA Posting Group" equal first's variants.
        CreateFAWithClassAndSubclass(FixedAsset, FAClass.Code, FASubclass[1].Code);

        // [GIVEN] FA Depreciation Book was created with first variant of FA Posting Group.
        FASetup.Get();
        CreateFADepreciationBookEmpty(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book", FAPostingGroup[1].Code);

        // [GIVEN] Field "Allow Changes in Depr. Fields" in  table DepreciationBook = FALSE
        CreateDepreciationBookWithAllowChangesInDeprField(DepreciationBook, false);

        // [WHEN] FA Subclass change in FixedAssetCard to second variant
        FixedAssetCard.OpenEdit();
        FixedAssetCard.FILTER.SetFilter("No.", FixedAsset."No.");
        FixedAssetCard."FA Subclass Code".SetValue(FASubclass[2].Code);
        FixedAssetCard.OK().Invoke();

        // [THEN] The FA Subclass Code was changed, FADepreciationBook."FA Posting Group" is changed
        FixedAsset.Find();
        FADepreciationBook.Find();
        FixedAsset.TestField("FA Subclass Code", FASubclass[2].Code);
        FADepreciationBook.TestField("FA Posting Group", FAPostingGroup[2].Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFACardBookDisposalValueOnDrillDown()
    var
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubclass: Record "FA Subclass";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FADepreciationBook: Record "FA Depreciation Book";
        DummyFALedgerEntry: Record "FA Ledger Entry";
        FixedAssetStatistics: TestPage "Fixed Asset Statistics";
        FixedAssetCard: TestPage "Fixed Asset Card";
        FALedgerEntries: TestPage "FA Ledger Entries";
        DisposalValue: Decimal;
    begin
        // [FEATURE] [Disposal] [Disposal Value]
        // [SCENARIO 330253] It should be no lines in FA Ledger Entries when drilldown Disposal Value from FA Statistics page for FA Document that was not disposed.
        // [GIVEN] FA Setup in place, and a disposed fixed asset with
        // [GIVEN] FA Posting Type = Book Value on Disposal
        // [GIVEN] Disposal Amount = "D"
        FASetup.Get();
        CreateFAWithClassPostingGroupAndSubclass(FAPostingGroup, FAClass, FASubclass, FixedAsset);
        DisposalValue := LibraryRandom.RandDecInRange(10, 1000, 2);
        CreateFADepreciationBookWithValue(
          FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book", FAPostingGroup.Code, DisposalValue);

        // [GIVEN] Page FixedAssetStatistics is opened.
        FixedAssetCard.OpenEdit();
        FixedAssetCard.FILTER.SetFilter("No.", FixedAsset."No.");
        FixedAssetStatistics.Trap();
        FixedAssetCard.Statistics.Invoke();
        FALedgerEntries.OpenView();
        FALedgerEntries.Trap();

        // [WHEN] User press DrillDown on the DisposalValue field.
        FixedAssetStatistics.DisposalValue.DrillDown();

        // [THEN] There are no lines in opened page FALedgerEntries.
        Assert.IsTrue(FALedgerEntries.First(), 'FA Ledger Entry does not exist after drilldown DispovalValue');

        // [THEN] Line have next parametrs: Amount = "D", FA Posting Type = "Acquisition Cost", FA Posting Category =' '
        Assert.AreEqual(FALedgerEntries.Amount.Value, Format(DisposalValue), 'FA doc.');
        Assert.AreEqual(
          FALedgerEntries."FA Posting Type".Value,
          Format(DummyFALedgerEntry."FA Posting Type"::"Acquisition Cost"),
          DummyFALedgerEntry.FieldCaption("FA Posting Type"));
        Assert.AreEqual(
          FALedgerEntries."FA Posting Category".Value,
          Format(DummyFALedgerEntry."FA Posting Category"::" "),
          DummyFALedgerEntry.FieldCaption("FA Posting Category"));

        // [THEN] There are no more "FA Ledger Entries" lines.
        Assert.IsFalse(FALedgerEntries.Next(), 'No more records expected');

        FALedgerEntries.Close();
        FixedAssetCard.Close();
        FixedAssetStatistics.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetFAPostingGroupOnNewFixedAsset()
    var
        FixedAsset: Record "Fixed Asset";
        FAPostingGroup: Record "FA Posting Group";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAssetCard: TestPage "Fixed Asset Card";
    begin
        // [FEATURE] [UI] [Posting Group] [Depreciation]
        // [SCENARIO 356263] Stan can't set Posting Group on Fixed Asset Card page when FA Depreciation Book is not specified yet.

        // [GIVEN] Fixed Asset without "FA Posting Group" and associated FA Depreciation Book
        FixedAssetCard.OpenNew();
        FixedAssetCard.Description.SetValue(LibraryUtility.GenerateGUID());
        FixedAsset.Get(FixedAssetCard."No.".Value);
        FixedAssetCard.Close();

        FixedAsset.Find();
        FixedAsset.TestField("FA Posting Group", '');
        FADepreciationBook.SetRange("FA No.", FixedAsset."No.");
        Assert.RecordIsEmpty(FADepreciationBook);

        // [GIVEN]"FA Posting Group" with Code = "FA_TEST"
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);

        // [WHEN] Stan validates "Posting Group" field with "FA_TEST" on Fixed Asset Card page
        FixedAssetCard.OpenEdit();
        FixedAssetCard.Filter.SetFilter("No.", FixedAsset."No.");
        FixedAssetCard.FAPostingGroup.SetValue(FAPostingGroup.Code);
        FixedAssetCard.Close();

        // [THEN] "FA Posting Group" field of Fixed Asset remains blank as the page relies on Depreciation Book and its "FA Posting Group" field
        // [THEN] "FA Deprecation Book" is not created for the Fixed Asset.
        FixedAsset.Find();
        FixedAsset.TestField("FA Posting Group", '');
        FADepreciationBook.SetRange("FA No.", FixedAsset."No.");
        Assert.RecordIsEmpty(FADepreciationBook);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFACardFAPostingGroupValidation()
    var
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubclass: Record "FA Subclass";
        FAPostingGroup: Record "FA Posting Group";
        FixedAssetCard: TestPage "Fixed Asset Card";
        Description: Text[100];
    begin
        // [FEATURE] [Posting Group]
        // [SCENARIO 358751] System assigns "Default FA Posting Group" from "FA Sub Class" to newly created Fixed Asset when "FA Class Code" is already set in fixed asset.

        // [GIVEN] FA Posting group
        // [GIVEN] FA Class
        // [GIVEN] FA Subclass with "FA Class", and "Default FA Posting Group" set
        FixedAsset.DeleteAll();
        CreateRelatedFAClassFASubclassFAPostingGroup(FAClass, FASubclass, FAPostingGroup);
        Description := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(FixedAsset.Description)), 1, MaxStrLen(FixedAsset.Description));

        // [GIVEN] Fixed Asset Card was open
        FixedAssetCard.OpenNew();
        FixedAssetCard.Description.SetValue(Description);

        // [GIVEN] FA Class was set on Fixed Asset
        FixedAssetCard."FA Class Code".SetValue(FAClass.Code);

        // [WHEN] FA Subclass was set
        FixedAssetCard."FA Subclass Code".SetValue(FASubclass.Code);
        FixedAssetCard.Close();

        // [THEN] Fixed Asset "FA Posting Group" was assigned from FA Subclass "Default FA Posting Group"
        FixedAsset.FindFirst();
        FixedAsset.TestField("FA Posting Group", FAPostingGroup.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFACardFAPostingGroupValidationWhenChangeFASubclassToEmpty()
    var
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubclass: Record "FA Subclass";
        FAPostingGroup: Record "FA Posting Group";
    begin
        // [FEATURE] [Posting Group]
        // [SCENARIO 367323] System reset the FA Posting Group, when the FA Subclass is changed to empty

        // [GIVEN] Created related FA Class, FA Subclass and FA Posting Group
        CreateRelatedFAClassFASubclassFAPostingGroup(FAClass, FASubclass, FAPostingGroup);
        CreateFAWithClassAndSubclass(FixedAsset, FAClass.Code, FASubclass.Code);

        // [GIVEN] Change FA Subclass Code to ''
        FixedAsset.Validate("FA Subclass Code", '');

        // [THEN] FA Posting group reset too.
        FixedAsset.TestField("FA Posting Group", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFAUpdateFASubclassToEmptyWhenDefaultFAPostingGroupIsDefined()
    var
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubclass: Record "FA Subclass";
        FAPostingGroup: Record "FA Posting Group";
    begin
        // [FEATURE] [Posting Group]
        // [SCENARIO 367323] System reset the FA Posting Group, when the FA Subclass is changed to empty when there is a "Default FA Posting Group" for FA Subclass

        // [GIVEN] Created related FA Class, FA Subclass and FA Posting Group
        CreateRelatedFAClassFASubclassFAPostingGroup(FAClass, FASubclass, FAPostingGroup);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);

        // [GIVEN] Set up the "Default FA Posting Group" for FA Subclass
        FASubclass.Validate("Default FA Posting Group", FAPostingGroup.Code);
        FASubclass.Modify(true);

        FixedAsset.Validate("FA Class Code", FAClass.Code);
        FixedAsset.Validate("FA Subclass Code", FASubclass.Code);
        FixedAsset.Modify(true);

        // [GIVEN] Change FA Subclass Code to ''
        FixedAsset.Validate("FA Subclass Code", '');

        // [THEN] FA Posting group reset too.
        FixedAsset.TestField("FA Posting Group", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFACardFAPostingGroupValidationWhenChangeFASubclassToEmptyAndThereAreFALedgerEntry()
    var
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubclass: Record "FA Subclass";
        FAPostingGroup: Record "FA Posting Group";
        DepreciationBook: Record "Depreciation Book";
    begin
        // [FEATURE] [Posting Group]
        // [SCENARIO 367323] System did not change the FA Posting Group, when the FA Subclass is changed to empty when there are FA Ledger Entries

        // [GIVEN] Created related FA Class, FA Subclass and FA Posting Group
        CreateRelatedFAClassFASubclassFAPostingGroup(FAClass, FASubclass, FAPostingGroup);
        CreateFAWithClassAndSubclass(FixedAsset, FAClass.Code, FASubclass.Code);

        // [GIVEN] Mock FA Ledger Entry for created Fixed Asset
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        MockFALedgerEntryBookValue(FixedAsset."No.", DepreciationBook.Code, WorkDate(), LibraryRandom.RandInt(100));

        // [GIVEN] Change FA Subclass Code to ''
        asserterror FixedAsset.Validate("FA Subclass Code", '');

        // [THEN] FA Posting Group did not changed
        // [THEN] The Error "You cannot change the FA Posting Group, when there is FA Ledger Entries." was shown
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(FoundFALedgerEntriesErr);
        FixedAsset.TestField("FA Posting Group", FAPostingGroup.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFACardFAPostingGroupValidationWhenChangeFASubclass()
    var
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubclass: array[2] of Record "FA Subclass";
        FAPostingGroup: array[2] of Record "FA Posting Group";
    begin
        // [FEATURE] [Posting Group]
        // [SCENARIO 367323] System did not change the FA Posting Group, when the FA Subclass is changed to new value

        // [GIVEN] Created related FA Class, FA Subclass and FA Posting Group
        CreateRelatedFAClassFASubclassFAPostingGroup(FAClass, FASubclass[1], FAPostingGroup[1]);

        // [GIVEN] Created related FA Class, FA Subclass and FA Posting Group
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup[2]);
        LibraryFixedAsset.CreateFASubclassDetailed(FASubclass[2], FAClass.Code, FAPostingGroup[2].Code);

        CreateFAWithClassAndSubclass(FixedAsset, FAClass.Code, FASubclass[1].Code);

        // [WHEN] Changed FA Subclass to FA Subclass 2
        FixedAsset.Validate("FA Subclass Code", FASubclass[2].Code);

        // [THEN] FA Posting group did not change
        FixedAsset.TestField("FA Posting Group", FAPostingGroup[1].Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFACardFAPostingGroupValidationWhenChangeFASubclassWithFALedgerEntry()
    var
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubclass: array[2] of Record "FA Subclass";
        FAPostingGroup: array[2] of Record "FA Posting Group";
        DepreciationBook: Record "Depreciation Book";
    begin
        // [FEATURE] [Posting Group]
        // [SCENARIO 367323]  System did not change the FA Posting Group, when the FA Subclass is changed to new value, when there are FA Ledger Entries

        // [GIVEN] Created related FA Class 1, FA Subclass 1 and FA Posting Group 1
        CreateRelatedFAClassFASubclassFAPostingGroup(FAClass, FASubclass[1], FAPostingGroup[1]);

        // [GIVEN] Created related FA Class 2, FA Subclass 2 and FA Posting Group 2
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup[2]);
        LibraryFixedAsset.CreateFASubclassDetailed(FASubclass[2], FAClass.Code, FAPostingGroup[2].Code);

        // [GIVEN] Created Fixed Asset
        CreateFAWithClassAndSubclass(FixedAsset, FAClass.Code, FASubclass[1].Code);

        // [GIVEN] Mock FA Ledger Entry for created Fixed Asset
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        MockFALedgerEntryBookValue(FixedAsset."No.", DepreciationBook.Code, WorkDate(), LibraryRandom.RandInt(100));

        // [WHEN] Changed FA Subclass to FA Subclass 2
        FixedAsset.Validate("FA Subclass Code", FASubclass[2].Code);

        // [THEN] FA Posting group did not change
        FixedAsset.TestField("FA Posting Group", FAPostingGroup[1].Code);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerEnque')]
    [Scope('OnPrem')]
    procedure TestFACardPageFAPostingGroupValidationWhenChangeFASubclassWithFALedgerEntry()
    var
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubclass: array[2] of Record "FA Subclass";
        FAPostingGroup: array[2] of Record "FA Posting Group";
        FADepreciationBook: Record "FA Depreciation Book";
        FASetup: Record "FA Setup";
        FixedAssetCard: TestPage "Fixed Asset Card";
        ExpectedMessage: Text;
    begin
        // [FEATURE] [Posting Group]
        // [SCENARIO 383692] Create FA document with FA Ledger entry and edit FA Subclass on Fixed Asset Card page. The FA Posting Group of FA Depreciation book is not changed.

        // [GIVEN] 2 different FAPostingGroup were created, 2 different FASubclass were created, FAClass and DepreciationBook were created.
        CreateFAClassWithTwoDetailedSubclasses(FAClass, FASubclass, FAPostingGroup);

        // [GIVEN] FixedAsset was created with "FA Subclass Code" and "FA Posting Group" equal first's variants.
        CreateFAWithClassAndSubclass(FixedAsset, FAClass.Code, FASubclass[1].Code);

        // [GIVEN] FA Depreciation Book with FA Ledger Entry was created with first variant of FA Posting Group.
        FASetup.Get();
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book", FAPostingGroup[1].Code);

        // [WHEN] FA Subclass change in FixedAssetCard to second variant.
        FixedAssetCard.OpenEdit();
        FixedAssetCard.FILTER.SetFilter("No.", FixedAsset."No.");
        FixedAssetCard."FA Subclass Code".SetValue(FASubclass[2].Code);
        FixedAssetCard.OK().Invoke();

        // [THEN] FA Posting Group is not changed message, the FA Subclass Code is changed, FADepreciationBook."FA Posting Group" is not changed.
        ExpectedMessage := StrSubstNo(
            FAPostingGroupChangeDeniedTxt, FAPostingGroup[1].Code, FASubclass[2].Code, FASubclass[2]."Default FA Posting Group");
        Assert.ExpectedMessage(ExpectedMessage, LibraryVariableStorage.DequeueText());
        FixedAsset.Find();
        FADepreciationBook.Find();
        FixedAsset.TestField("FA Subclass Code", FASubclass[2].Code);
        FixedAsset.TestField("FA Posting Group", FAPostingGroup[1].Code);
        FADepreciationBook.TestField("FA Posting Group", FAPostingGroup[1].Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerEnque')]
    [Scope('OnPrem')]
    procedure TestFACardPageFAPostingGroupValidationConfirmNoWhenChangeFASubclass()
    var
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubclass: array[2] of Record "FA Subclass";
        FAPostingGroup: array[2] of Record "FA Posting Group";
        FADepreciationBook: Record "FA Depreciation Book";
        FASetup: Record "FA Setup";
        FixedAssetCard: TestPage "Fixed Asset Card";
        ExpectedMessage: Text;
    begin
        // [FEATURE] [Posting Group]
        // [SCENARIO 383692] Create FA document and edit FA Subclass on Fixed Asset Card page. After denying confirm the FA Posting Group of FA Depreciation book is not changed.

        // [GIVEN] 2 different FAPostingGroup were created, 2 different FASubclass were created, FAClass and DepreciationBook were created.
        CreateFAClassWithTwoDetailedSubclasses(FAClass, FASubclass, FAPostingGroup);

        // [GIVEN] FixedAsset was created with "FA Subclass Code" and "FA Posting Group" equal first's variants.
        CreateFAWithClassAndSubclass(FixedAsset, FAClass.Code, FASubclass[1].Code);

        // [GIVEN] FA Depreciation Book was created with first variant of FA Posting Group.
        FASetup.Get();
        CreateFADepreciationBookEmpty(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book", FAPostingGroup[1].Code);

        // [WHEN] FA Subclass changed in FixedAssetCard to second variant and confirm about changing FA Posting Group is denied.
        LibraryVariableStorage.Enqueue(false);
        FixedAssetCard.OpenEdit();
        FixedAssetCard.FILTER.SetFilter("No.", FixedAsset."No.");
        FixedAssetCard."FA Subclass Code".SetValue(FASubclass[2].Code);
        FixedAssetCard.OK().Invoke();

        // [THEN] The FA Subclass Code is changed, FADepreciationBook."FA Posting Group" is not changed.
        ExpectedMessage := StrSubstNo(
            FAPostingGroupChangeConfirmTxt, FAPostingGroup[1].Code, FASubclass[2].Code, FASubclass[2]."Default FA Posting Group");
        Assert.ExpectedMessage(ExpectedMessage, LibraryVariableStorage.DequeueText());
        FixedAsset.Find();
        FADepreciationBook.Find();
        FixedAsset.TestField("FA Subclass Code", FASubclass[2].Code);
        FixedAsset.TestField("FA Posting Group", FAPostingGroup[1].Code);
        FADepreciationBook.TestField("FA Posting Group", FAPostingGroup[1].Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerEnque')]
    [Scope('OnPrem')]
    procedure TestFACardPageFAPostingGroupValidationConfirmYesWhenChangeFASubclass()
    var
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubclass: array[2] of Record "FA Subclass";
        FAPostingGroup: array[2] of Record "FA Posting Group";
        FADepreciationBook: Record "FA Depreciation Book";
        FASetup: Record "FA Setup";
        FixedAssetCard: TestPage "Fixed Asset Card";
        ExpectedMessage: Text;
    begin
        // [FEATURE] [Posting Group]
        // [SCENARIO 383692] Create FA document and edit FA Subclass on Fixed Asset Card page. After accepting confirm the FA Posting Group of FA Depreciation book is changed.

        // [GIVEN] 2 different FAPostingGroup were created, 2 different FASubclass were created, FAClass and DepreciationBook were created.
        CreateFAClassWithTwoDetailedSubclasses(FAClass, FASubclass, FAPostingGroup);

        // [GIVEN] FixedAsset was created with "FA Subclass Code" and "FA Posting Group" equal first's variants.
        CreateFAWithClassAndSubclass(FixedAsset, FAClass.Code, FASubclass[1].Code);

        // [GIVEN] FA Depreciation Book was created with first variant of FA Posting Group.
        FASetup.Get();
        CreateFADepreciationBookEmpty(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book", FAPostingGroup[1].Code);

        // [WHEN] FA Subclass changed in FixedAssetCard to second variant and confirm about changing FA Posting Group is accepted.
        LibraryVariableStorage.Enqueue(true);
        FixedAssetCard.OpenEdit();
        FixedAssetCard.FILTER.SetFilter("No.", FixedAsset."No.");
        FixedAssetCard."FA Subclass Code".SetValue(FASubclass[2].Code);
        FixedAssetCard.OK().Invoke();

        // [THEN] The FA Subclass Code is changed, FADepreciationBook."FA Posting Group" is changed.
        ExpectedMessage := StrSubstNo(
            FAPostingGroupChangeConfirmTxt, FAPostingGroup[1].Code, FASubclass[2].Code, FASubclass[2]."Default FA Posting Group");
        Assert.ExpectedMessage(ExpectedMessage, LibraryVariableStorage.DequeueText());
        FixedAsset.Find();
        FixedAsset.TestField("FA Subclass Code", FASubclass[2].Code);
        FixedAsset.TestField("FA Posting Group", FAPostingGroup[2].Code);
        FADepreciationBook.Find();
        FADepreciationBook.TestField("FA Posting Group", FAPostingGroup[2].Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerEnque')]
    [Scope('OnPrem')]
    procedure TestFACardPageFAPostingGroupUpdateOnSubPageAfterChangingFASubclass()
    var
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubclass: array[2] of Record "FA Subclass";
        FAPostingGroup: array[2] of Record "FA Posting Group";
        FADepreciationBook: Record "FA Depreciation Book";
        FASetup: Record "FA Setup";
        FixedAssetCard: TestPage "Fixed Asset Card";
        ExpectedMessage: Text;
    begin
        // [FEATURE] [Posting Group]
        // [SCENARIO 383692] Create FA document and edit FA Subclass on Fixed Asset Card page. After accepting confirm the FA Posting Group of FA Depreciation book is updated on subpage.

        // [GIVEN] 2 different FAPostingGroup were created, 2 different FASubclass were created, FAClass and DepreciationBook were created.
        CreateFAClassWithTwoDetailedSubclasses(FAClass, FASubclass, FAPostingGroup);

        // [GIVEN] FixedAsset was created with "FA Subclass Code" and "FA Posting Group" equal first's variants.
        CreateFAWithClassAndSubclass(FixedAsset, FAClass.Code, FASubclass[1].Code);

        // [GIVEN] FA Depreciation Book was created with first variant of FA Posting Group.
        FASetup.Get();
        CreateFADepreciationBookEmpty(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book", FAPostingGroup[1].Code);

        // [WHEN] FixedAssetCard opened in not simple mode by AddMoreDeprBooks drilldown, FA Subclass is changed to second variant and confirm about changing FA Posting Group is accepted.
        LibraryVariableStorage.Enqueue(true);
        FixedAssetCard.OpenEdit();
        FixedAssetCard.FILTER.SetFilter("No.", FixedAsset."No.");
        FixedAssetCard.AddMoreDeprBooks.DrillDown();
        FixedAssetCard."FA Subclass Code".SetValue(FASubclass[2].Code);

        // [THEN] "FA Posting Group" of FA Depreciation Book is updated on subpage.
        ExpectedMessage := StrSubstNo(
            FAPostingGroupChangeConfirmTxt, FAPostingGroup[1].Code, FASubclass[2].Code, FASubclass[2]."Default FA Posting Group");
        Assert.ExpectedMessage(ExpectedMessage, LibraryVariableStorage.DequeueText());
        FixedAssetCard.DepreciationBook."FA Posting Group".AssertEquals(FAPostingGroup[2].Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UserCanChangeDeprBookInSimpleModeNewFixedAssetCard()
    var
        FixedAssetCard: TestPage "Fixed Asset Card";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 401954] User can change Depreciation Book in simple mode of Fixed Asset card for new FA

        FixedAssetCard.OpenNew();
        Assert.IsTrue(FixedAssetCard.DepreciationBookCode.Editable(), 'The field "Depreciation Book Code" must be editable.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UserCannotChangeDeprBookInSimpleModeEditFixedAssetCard()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAssetCard: TestPage "Fixed Asset Card";
    begin
        // [FEATURE] [UT] [ui]
        // [SCENARIO 401954] User can change Depreciation Book in simple mode of Fixed Asset card for new FA

        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);

        FixedAssetCard.OpenEdit();
        FixedAssetCard.FILTER.SetFilter("No.", FixedAsset."No.");
        Assert.IsFalse(FixedAssetCard.DepreciationBookCode.Editable(), 'The field "Depreciation Book Code" must not be editable.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeFASubclassCodeWithSameFAPostingGroup()
    var
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FASubclass: Record "FA Subclass";
        FAPostingGroup: Record "FA Posting Group";
        FADepreciationBook: Record "FA Depreciation Book";
        FASetup: Record "FA Setup";
        FixedAssetCard: TestPage "Fixed Asset Card";
    begin
        // [GIVEN] Fixed asset "FA" with FA subclass "FASub1" with FA posting group "FAPG" and FA depreciation book "FADB" with depreciation
        FASetup.Get();
        FixedAsset.DeleteAll();
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        CreateRelatedFAClassFASubclassFAPostingGroup(FAClass, FASubclass, FAPostingGroup);
        FixedAsset.Validate("FA Class Code", FAClass.Code);
        FixedAsset.Validate("FA Subclass Code", FASubclass.Code);
        FixedAsset.Modify(true);
        CreateFADepreciationBookWithValue(FADepreciationBook, FixedAsset."No.", FASetup."Default Depr. Book", FASubclass."Default FA Posting Group", 1000);
        FADepreciationBook."Last Depreciation Date" := WorkDate();
        FADepreciationBook.Modify();

        // [WHEN] Change FA subclass code on the fixed asset card to "FASub2" with FA posting group "FAPG"
        LibraryFixedAsset.CreateFASubclassDetailed(FASubclass, FAClass.Code, FAPostingGroup.Code);
        FixedAssetCard.OpenEdit();
        FixedAssetCard.GoToRecord(FixedAsset);
        FixedAssetCard."FA Subclass Code".SetValue(FASubclass.Code);

        // [THEN] FA subclass code = "FASub2" and updated without any messages/errors
        FixedAssetCard."FA Subclass Code".AssertEquals(FASubclass.Code);
        // [THEN] FA depreciation book "FA Posting Group" = "FAPG"
        FADepreciationBook.Get(FixedAsset."No.", FASetup."Default Depr. Book");
        FADepreciationBook.TestField("FA Posting Group", FAPostingGroup.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S468467_FixedAssetDescriptionCopiedToFADepreciationBookDescription_FADescriptionAfterDepreciationBookCode()
    var
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
        FASubclass: Record "FA Subclass";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAssetCard: TestPage "Fixed Asset Card";
        DescriptionToSet: Text[100];
    begin
        // [FEATURE] [UT] [Fixed Asset Card]
        // [SCENARIO 401954] "Fixed Asset".Description is copied to "FA Depreciation Book".Description when "Fixed Asset Card".Description is defined after "Fixed Asset Card".DepreciationBookCode.

        // [GIVEN] FA Setup is in place.
        FixedAssetAndDeprecationBookSetup(FASubclass);
        FASetup.Get();
        DescriptionToSet := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(FixedAsset.Description)), 1, MaxStrLen(FixedAsset.Description));

        // [GIVEN] Fixed Asset is created.
        FixedAssetCard.OpenNew();

        // [GIVEN] Fixed Asset is DepreciationBookCode is defined.
        FixedAssetCard.DepreciationBookCode.SetValue(FASetup."Default Depr. Book");

        // [WHEN] Fixed Asset is Description is defined.
        FixedAssetCard.Description.SetValue(DescriptionToSet);
        FixedAssetCard.Close();

        // [WHEN] There is one "FA Depreciation Book" record for created Fixed Asset and its Description is equal to Description of Fixed Asset.
        FixedAsset.FindFirst();
        FADepreciationBook.SetRange("FA No.", FixedAsset."No.");
        Assert.RecordCount(FADepreciationBook, 1);

        FADepreciationBook.FindFirst();
        FADepreciationBook.TestField("Depreciation Book Code", FASetup."Default Depr. Book");
        FADepreciationBook.TestField(Description, DescriptionToSet);
    end;

    local procedure FixedAssetAndDeprecationBookSetup(var FASubclass: Record "FA Subclass")
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAClass: Record "FA Class";
        FAPostingGroup: Record "FA Posting Group";
    begin
        FixedAsset.DeleteAll();
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        CreateRelatedFAClassFASubclassFAPostingGroup(FAClass, FASubclass, FAPostingGroup);
    end;

    local procedure CreateFAClassWithTwoDetailedSubclasses(var FAClass: Record "FA Class"; var FASubclass: array[2] of Record "FA Subclass"; var FAPostingGroup: array[2] of Record "FA Posting Group")
    begin
        LibraryFixedAsset.CreateFAClass(FAClass);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup[1]);
        LibraryFixedAsset.CreateFASubclassDetailed(FASubclass[1], FAClass.Code, FAPostingGroup[1].Code);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup[2]);
        LibraryFixedAsset.CreateFASubclassDetailed(FASubclass[2], FAClass.Code, FAPostingGroup[2].Code);
    end;

    [Scope('OnPrem')]
    procedure CreateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; FANo: Code[20]; DepreciationBookCode: Code[10]; PostingGroupCode: Code[20])
    begin
        CreateFADepreciationBookWithValue(
          FADepreciationBook,
          FANo,
          DepreciationBookCode,
          PostingGroupCode,
          LibraryRandom.RandDecInRange(10, 1000, 0));
    end;

    [Scope('OnPrem')]
    procedure CreateFADepreciationBookEmpty(var FADepreciationBook: Record "FA Depreciation Book"; FANo: Code[20]; DepreciationBookCode: Code[10]; PostingGroupCode: Code[20])
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FANo, DepreciationBookCode);
        FADepreciationBook."FA Posting Group" := PostingGroupCode;
        FADepreciationBook."Depreciation Method" := FADepreciationBook."Depreciation Method"::"Declining-Balance 1";
        FADepreciationBook."Depreciation Starting Date" := 0D;
        FADepreciationBook."Depreciation Ending Date" := 0D;
        FADepreciationBook.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateFADepreciationBookWithValue(var FADepreciationBook: Record "FA Depreciation Book"; FANo: Code[20]; DepreciationBookCode: Code[10]; PostingGroupCode: Code[20]; BookValue: Decimal)
    begin
        CreateFADepreciationBookEmpty(FADepreciationBook, FANo, DepreciationBookCode, PostingGroupCode);
        MockFALedgerEntryBookValue(FANo, DepreciationBookCode, WorkDate(), BookValue);
    end;

    local procedure DisposeFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; BookValue: Decimal)
    var
        DummyFALedgerEntry: Record "FA Ledger Entry";
    begin
        MockFALedgerEntryDisposal(
          FADepreciationBook."FA No.",
          FADepreciationBook."Depreciation Book Code",
          WorkDate(), BookValue,
          DummyFALedgerEntry."FA Posting Type"::"Acquisition Cost");
        MockFALedgerEntryDisposal(
          FADepreciationBook."FA No.",
          FADepreciationBook."Depreciation Book Code",
          WorkDate(), -BookValue,
          DummyFALedgerEntry."FA Posting Type"::"Book Value on Disposal");
        FADepreciationBook."Disposal Date" := WorkDate();
        FADepreciationBook.Modify(true);
    end;

    local procedure MockFALedgerEntryBookValue(FANo: Code[20]; DepreciationBookCode: Code[10]; FAPostingDate: Date; BookValueAmount: Decimal)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.Init();
        FALedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(FALedgerEntry, FALedgerEntry.FieldNo("Entry No."));
        FALedgerEntry."FA No." := FANo;
        FALedgerEntry."Depreciation Book Code" := DepreciationBookCode;
        FALedgerEntry."Part of Book Value" := true;
        FALedgerEntry."FA Posting Date" := FAPostingDate;
        FALedgerEntry.Amount := BookValueAmount;
        FALedgerEntry.Insert();
    end;

    local procedure MockFALedgerEntryDisposal(FANo: Code[20]; DepreciationBookCode: Code[10]; FAPostingDate: Date; BookValueAmount: Decimal; FAPostingType: Enum "FA Ledger Entry FA Posting Type")
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.Init();
        FALedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(FALedgerEntry, FALedgerEntry.FieldNo("Entry No."));
        FALedgerEntry."FA No." := FANo;
        FALedgerEntry."Depreciation Book Code" := DepreciationBookCode;
        FALedgerEntry."FA Posting Category" := FALedgerEntry."FA Posting Category"::Disposal;
        FALedgerEntry."FA Posting Type" := FAPostingType;
        FALedgerEntry."FA Posting Date" := FAPostingDate;
        FALedgerEntry.Amount := -BookValueAmount;
        FALedgerEntry.Insert();
    end;

    local procedure ValidateBookValueMultibook(FixedAssetCard: TestPage "Fixed Asset Card"; DepreciationBookCode: Code[10]; BookValue: Decimal)
    begin
        FixedAssetCard.DepreciationBook."Depreciation Book Code".AssertEquals(DepreciationBookCode);
        FixedAssetCard.DepreciationBook.BookValue.AssertEquals(BookValue);
    end;

    local procedure ValidateBookValueSimple(FixedAssetCard: TestPage "Fixed Asset Card"; DepreciationBookCode: Code[10]; BookValue: Decimal)
    begin
        FixedAssetCard.DepreciationBookCode.AssertEquals(DepreciationBookCode);
        FixedAssetCard.BookValue.AssertEquals(BookValue);
    end;

    local procedure CreateFAWithClassAndSubclass(var FixedAsset: Record "Fixed Asset"; FAClassCode: Code[10]; FASubclassCode: Code[10])
    begin
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FixedAsset.Validate("FA Class Code", FAClassCode);
        FixedAsset.Validate("FA Subclass Code", FASubclassCode);
        FixedAsset.Modify(true);
    end;

    local procedure CreateFAWithClassPostingGroupAndSubclass(var FAPostingGroup: Record "FA Posting Group"; var FAClass: Record "FA Class"; var FASubclass: Record "FA Subclass"; var FixedAsset: Record "Fixed Asset")
    begin
        CreateRelatedFAClassFASubclassFAPostingGroup(FAClass, FASubclass, FAPostingGroup);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
    end;

    [Scope('OnPrem')]
    procedure CreateDepreciationBookWithAllowChangesInDeprField(var DepreciationBook: Record "Depreciation Book"; AllowChangesInDeprFields: Boolean)
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("Allow Changes in Depr. Fields", AllowChangesInDeprFields);
        DepreciationBook.Modify(true);
    end;

    local procedure CreateRelatedFAClassFASubclassFAPostingGroup(var FAClass: Record "FA Class"; var FASubclass: Record "FA Subclass"; var FAPostingGroup: Record "FA Posting Group")
    begin
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFAClass(FAClass);
        LibraryFixedAsset.CreateFASubclassDetailed(FASubclass, FAClass.Code, FAPostingGroup.Code);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FASubclassValidationHandler(var FASubclasses: TestPage "FA Subclasses")
    var
        SubclassCode: Code[10];
    begin
        SubclassCode := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(SubclassCode));
        Assert.IsTrue(FASubclasses.FindFirstField(Code, SubclassCode), SubclassCode + ' should be include in lookup');

        SubclassCode := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(SubclassCode));
        Assert.IsTrue(FASubclasses.FindFirstField(Code, SubclassCode), SubclassCode + ' should be include in lookup');

        SubclassCode := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(SubclassCode));
        Assert.IsFalse(FASubclasses.FindFirstField(Code, SubclassCode), SubclassCode + ' should not be include in lookup');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerEnque(Question: Text[1024]; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerEnque(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;
}

