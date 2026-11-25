# Enterprise Data Quality Control Center — Power BI build guide

Independent portfolio demonstration; all source data is fictional. Do not use employer files, screenshots or identifiers. The browser dashboard is not a PBIX report.

## 1. Import the dataset
1. Open Power BI Desktop on Windows (a Windows VM or remote Windows computer is needed on macOS).
2. Select Home > Get data > Text/CSV. Choose `data/contacts.csv` and Transform Data.
3. Rename the query `Contacts`. Set all 10 columns to text. Confirm unique RecordID; there are 300 rows.
4. Filter Status to Active: 270 records remain. Keep all other fields.

## 2. Create an exceptions table in Power Query
Select Home > New Source > Blank Query, rename it `Exceptions`, open Advanced Editor and replace its content with the M code in `Exceptions.m`. Select Done, then Close & Apply. The table contains one row per record/rule occurrence. Check that it contains 88 rows and 77 distinct RecordIDs.

## 3. Model
In Model view, create a one-to-many relationship from Contacts[RecordID] to Exceptions[RecordID], single cross-filter direction (Contacts -> Exceptions). Region and SourceSystem slicers should use Contacts fields. Do not let an exception-type selection change the denominator for quality rate.

## 4. Measures
Create each measure separately under Contacts (or a dedicated measures table).

```dax
Active Contacts = DISTINCTCOUNT(Contacts[RecordID])
Affected Contacts = COALESCE(CALCULATE(DISTINCTCOUNT(Exceptions[RecordID]), REMOVEFILTERS(Exceptions[IssueType])), 0)
Total Exceptions = COALESCE(CALCULATE(COUNTROWS(Exceptions), REMOVEFILTERS(Exceptions[IssueType])), 0)
Quality Pass Rate = DIVIDE([Active Contacts] - [Affected Contacts], [Active Contacts])
Affected per Rule = COALESCE(DISTINCTCOUNT(Exceptions[RecordID]), 0)
```

Format Quality Pass Rate as percentage with one decimal. Overall baseline: 270 active, 77 affected, 88 exceptions, 71.5% pass rate. Rule counts: missing registration 14; duplicate registration 18; duplicate email 22; mismatch 20; incomplete 14. Affected counts overlap.

## 5. Report layout
Use a 16:9 page (1280 x 720) with navy background #08131E, cards #102233, accent #71E5BE and text #EEF6FC. Place four KPI cards at the top using the first four measures. Add a horizontal bar chart with Exceptions[IssueType] and Affected per Rule; add a second bar chart with Contacts[Region] and Quality Pass Rate. Add slicers for Region and SourceSystem. Add a detail table using Contacts[RecordID], Contacts[FullName], Contacts[Region], Contacts[SourceSystem], Exceptions[IssueType]. Because exceptions contain one row per issue, the table may repeat IDs. Set a visual filter on Affected per Rule > 0 if needed. Add a separate issue-type slicer for details only, and use Edit interactions to disable its effect on other visuals if desired. Use View > Themes > Customize current theme for styling. Add a small visible subtitle: Synthetic data only — independent portfolio project.

## 6. Verify
Compare counts with the web demo. Filter Region and Source; counts should recalculate. Duplicates are detected globally within active records before filtering, not separately per region. Verify that empties aren't treated as duplicates and inactive records are excluded. Quality pass rate must be blank for an empty denominator. Save as `Enterprise_Data_Quality.pbix`.

## 7. Publish
Option A: add report screenshots and a short demo recording to GitHub Pages. Option B: publish the PBIX to your personal Power BI workspace and, only if the license and tenant allow it, use File > Embed report > Publish to web (public). Public embed reveals report data to anyone; use only the fictional dataset. Never use your employer account or report. Microsoft documentation: https://learn.microsoft.com/en-us/power-bi/collaborate-share/service-publish-to-web
