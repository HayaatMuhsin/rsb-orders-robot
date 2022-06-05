*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Archive
Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.Dialogs
Library             RPA.HTTP
Library             RPA.PDF
Library             RPA.Robocorp.Vault
Library             RPA.Tables
Library             Screenshot


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${orders-file}=    Get orders file url
    Open the robot order website
    ${orders}=    Get orders    ${orders-file}
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    10x    2s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}
        ${screenshot}=    Take a screenshot of the robot    ${row}
        Embed the robot screenshot to the receipt PDF file    ${pdf}    ${screenshot}
        Go to order another robot
    END
    Close the browser
    Create a ZIP file of the receipts


*** Keywords ***
Get orders file url
    Add heading    Orders CSV File URL
    Add text    Please enter the url of the csv file with the orders to make the orders and generate receipts
    Add text input    url
    ${input}=    Run dialog
    RETURN    ${input.url}

Open the robot order website
    ${secret}=    Get Secret    urls
    Open Available Browser    ${secret}[order-page-url]
    Wait Until Element Is Visible    class=modal-header

Get orders
    [Arguments]    ${orders-file}
    Download    ${orders-file}    overwrite=True
    ${orders}=    Read table from CSV    orders.csv
    RETURN    ${orders}

Close the annoying modal
    Click Button    OK
    Wait Until Element Is Visible    head

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath=/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the robot
    Click Button    preview
    Wait Until Element Is Visible    robot-preview-image

Submit the order
    Click Button    order
    Wait Until Element Is Visible    receipt

Store the receipt as a PDF file
    [Arguments]    ${row}
    Set Local Variable    ${pdf}    ${OUTPUT_DIR}${/}receipts${/}${row}[Order number].pdf
    ${receipt-html}=    Get Element Attribute    receipt    outerHTML
    Html To Pdf    ${receipt-html}    ${pdf}
    RETURN    ${pdf}

Take a screenshot of the robot
    [Arguments]    ${row}
    Wait Until Element Is Visible    robot-preview-image
    Sleep    1sec
    ${screenshot}=    Capture Element Screenshot
    ...    robot-preview-image
    ...    ${OUTPUT_DIR}${/}screenshots${/}${row}[Order number].png
    RETURN    ${screenshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${pdf}    ${screenshot}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}

Go to order another robot
    Click Button    order-another

Close the browser
    Close Browser

Create a ZIP file of the receipts
    ${zip-file}=    Set Variable    ${OUTPUT_DIR}/receipts.zip
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${zip-file}
