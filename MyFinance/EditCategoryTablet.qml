import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Components.Pickers 1.3
import Ubuntu.Layouts 1.0

/* replace the 'incomplete' QML API U1db with the low-level QtQuick API */
import QtQuick.LocalStorage 2.0
import Ubuntu.Components.ListItems 1.3 as ListItem

import "utility.js" as Utility
import "categoryUtils.js" as CategoryUtils
import "storage.js" as Storage

/*
 Used in Main.qml to show the details of a selectd Person/contact in the contacts List. Used for Tablet

 NOTE: All the TextField have set 'hasClearButton: false'. If 'hasClearButton: true' is shown a clear button
 in the field, and when is used there are refresh problem of the TextField when another person is chosen in the list
*/
Column {

    id: editCategoryPageLayout
    anchors.fill: parent
    spacing: units.gu(3.5)
    anchors.leftMargin: units.gu(2)

    Rectangle{
        color: "transparent"
        width: parent.width
        height: units.gu(6)
    }

    /* A PopUp that display the operation result */
    Component {
        id: operationSuccessDialogue
        OperationSuccessResult{msg:"Operation executed successfully !"}
    }

    Component {
        id: operationFailureDialogue
        OperationFailSubCategory{msg:"SubCategory invalid or duplicated"}
    }   


    //-------- Category Name ------------
    Row{
        id: newCategoryRow
        spacing: units.gu(9.5)

        Label {
            id: newCategoryLabel
            anchors.verticalCenter: newCategoryField.verticalCenter
            text: i18n.tr("Category Name:")            
        }

        TextField {
            id: newCategoryField
            text: categoryEditPage.categoryName
            placeholderText: ""
            echoMode: TextInput.Normal
            readOnly: true
            width: units.gu(35)
        }
     }

     Row{
            spacing: units.gu(8)

            Label {
                id: newSubCategoryLabel
                anchors.verticalCenter: newSubCategoryField.verticalCenter
                text: i18n.tr("Add Subcategory:")
            }

            TextField {
                id: newSubCategoryField
                text: ""
                placeholderText: ""
                echoMode: TextInput.Normal
                readOnly: false
                width: units.gu(35)
            }

            Button {
                id: addSubCategoryButton
                objectName: "Add"
                text: i18n.tr("Add to List")
                width: units.gu(14)
                onClicked: {

                    var result = CategoryUtils.checkAndAddSubCategory(newSubCategoryField.text)                   
                    if(result){
                        PopupUtils.open(operationSuccessDialogue)

                        //old: if(categoryListModelToSave.count !== categoryListModelSaved.count)
                        if(headerLabel.text.indexOf("Modified") === -1) {
                           headerLabel.text = headerLabel.text +" (Modified - NOT Saved)"
                        }

                        newSubCategoryField.text =""
                    }else {
                        PopupUtils.open(operationFailureDialogue)                        
                    }
                }
            }
     }

    /* Subcategory List selector */
    Row{
          spacing: units.gu(11)
          width: newSubCategoryField.width

          Label{
              id: curSubCategoryListLabel
              anchors.verticalCenter: subCategoryChooserButton.verticalCenter
              text: i18n.tr("Subcategory:")
          }

          //----------- Sub Category selector PopUp --------------
          Component {
               id: popoverSubCategoryPickerComponent

               Dialog {

                   id: subCategoryPickerDialog                  
                   text: "Select the subcategory to remove"

                   OptionSelector {
                       id: subCategoryOptionSelector
                       expanded: true
                       multiSelection: false
                       model: categoryListModelToSave
                       containerHeight: itemHeight * 4
                   }

                   Component.onCompleted: {

                       subCategoryPickerDialog.title = "Subcategories: "+categoryListModelToSave.count

                       /* manage popup buttons */
                       if(categoryListModelToSave.count === 0) {
                          removeItemButton.enabled = false
                       }else{
                          removeItemButton.enabled = true
                       }
                   }

                   //-------- Command buttons ------------
                   Row{
                       id: removeSubCategoryRow
                       spacing: units.gu(2)

                       Button {
                           id: removeItemButton
                           objectName: "removeItem"
                           text: i18n.tr("Remove")
                           width: units.gu(14)
                           onClicked: {
                               CategoryUtils.removeSubCategory(subCategoryOptionSelector)

                               /* manage popup buttons */
                               if(categoryListModelToSave.count === 0) {
                                  removeItemButton.enabled = false
                               }else{
                                  removeItemButton.enabled = true
                               }

                               /* if the label don't contains the 'Modified'suffix, add it */
                               if(headerLabel.text.indexOf("Modified") === -1) {
                                  headerLabel.text = headerLabel.text +" (Modified - NOT Saved)"
                               }

                               subCategoryPickerDialog.title = "Subcategories: "+categoryListModelToSave.count
                           }
                       }

                       Button {
                           text: i18n.tr("Close")
                           width: units.gu(14)
                           onClicked: PopupUtils.close(subCategoryPickerDialog)
                       }
                   }
               }
          }

          //--------------------
          Button {
              id: subCategoryChooserButton
              text: i18n.tr( "Show/Edit...")
              width: units.gu(20)
              onClicked: {
                  PopupUtils.open(popoverSubCategoryPickerComponent,subCategoryChooserButton)
              }
          }
     }

    /* line separator */
    Rectangle {
          color: "grey"
          width: units.gu(100)
          anchors.horizontalCenter: parent.horizontalCenter
          height: units.gu(0.1)
    }

     Row{
        id: removeSubCategoryRow
        spacing: units.gu(2)

        /* transparent placeholder: required to place the content under the header */
        Rectangle {
            color: "transparent"
            width: editCategoryPageLayout.width/4
            height: units.gu(1)
        }

        /* Save to database the new Category and subcategory */
        Button {
            id: addButton
            objectName: "Save"
            text: i18n.tr("Save")
            width: units.gu(14)
            color: UbuntuColors.orange
            onClicked: {
                PopupUtils.open(confirmEditingCategory)
            }
        }

        /* Delete category, subcategory and ALL associated Expenses */
        Button {
            id: deleteCategoryButton
            objectName: "Delete"
            text: i18n.tr("Delete Category")
            width: units.gu(20)
            onClicked: {
                PopupUtils.open(confirmDeleteCategoryDialogue)
            }
        }
    }

    //-------------- Confirm Editing Categry and associated Subcategory ----------
    Component {
        id: confirmEditingCategory

        Dialog {
            id: confirmDialogue
            title: "Confirmation"
            text: i18n.tr("Save Category modifications ?")

            Button {
                text: "Cancel"
                onClicked: PopupUtils.close(confirmDialogue)
            }

            Button {
                text: "Save"
                onClicked: {
                    PopupUtils.close(confirmDialogue)

                    /* check for NEW category to insert/remove executing the diff between the two models */
                    for (var n=0; n < categoryListModelToSave.count; n++) {

                        if(! Storage.subCatNameExist(categoryListModelToSave.get(n).sub_cat_name,categoryListModelSaved) )
                        {
                           /* the the ListModel of the popup have a category not present in the saved ListModel */
                           Storage.insertNewSubCategory(categoryListModelToSave.get(n).sub_cat_name,categoryEditPage.categoryId);
                           /* init the sub_category_report table */
                           var lastSubCategoryId = Storage.getLastId('sub_category');
                           /* init to zero 'sub_category_report' table */
                           Storage.insertSubCategoryCurrentReport(lastSubCategoryId, 0);
                        }
                    }

                    /* check for category to remove */
                    for (var i=0; i < categoryListModelSaved.count; i++) {

                        if(! Storage.subCatNameExist(categoryListModelSaved.get(i).sub_cat_name,categoryListModelToSave) )
                        {
                           /*  remove entry in the  sub_category report table */
                           var subCategoryId = Storage.getSubCategoryIdByName(categoryListModelSaved.get(i).sub_cat_name);
                           //console.log("SubCategoryId to remove: "+subCategoryId);
                           Storage.deleteSubCategoryReport(subCategoryId);

                           var totalSubCategoryExpense = Storage.getExpsenseAmountForSubCategory(subCategoryId);
                           //console.log("Total SubCategory Expense amount: "+totalSubCategoryExpense);

                           Storage.deleteAllExpenseForSubCategory(subCategoryId);

                           /* convert to negative number */
                           var diffAmount = -1 * totalSubCategoryExpense;

                           /* update current report table removing the subcategry expenses */
                           if(diffAmount != 0){
                              Storage.updateCategoryReportCurrentAmount(categoryExpensePage.id, diffAmount);
                           }

                           /* the ListModel to save contains a category non present in the saved one */
                           Storage.deleteSubCategory(categoryListModelSaved.get(i).sub_cat_name,categoryEditPage.categoryId);
                        }
                     }

                     /* update the subcategory list shown in the popup  */
                     CategoryUtils.initCategoryListModelToSave(categoryEditPage.categoryId);

                     /* remove "Modified" suffix */
                     //headerLabel.text = "<b>"+ i18n.tr("Edit chosen category") +"</b>"
                     Storage.getAllCategory(); // to refresh amount shown in category List
                     PopupUtils.open(operationSuccessDialogue)
                }
            }
        }
    }


    /* Dialog to Ask a confirmation at delete operation for the Category, subcategory and associted expense */
   Component{
       id :confirmDeleteCategoryDialogue

       Dialog {
           id: confirmDeleteCategory
           title: "Confirmation"
           modal:true
           text:"Delete this Category with his subcategory and <b>ALL</b> associated expense ?"

           Label{
               id:operationresultLabel
               text: ""
           }

           Button {
               text: i18n.tr("Close")
               onClicked: PopupUtils.close(confirmDeleteCategory)
           }

           Button {
               id:deleteButton
               text: i18n.tr("Delete")
               onClicked: {

                   /* remove ALL data about the CATEGORY: reports, expense, subcategory */

                   var subCategoryIdList = Storage.getSubCategoryByCategoryId(categoryExpensePage.id);
                   for(var i=0; i<subCategoryIdList.rows.length; i++){
                      Storage.deleteSubCategoryReport(subCategoryIdList.rows.item(i).id)
                   }

                   Storage.deleteCategory(categoryExpensePage.id);
                   Storage.deleteAllSubCategoryForCategory(categoryExpensePage.id);
                   Storage.deleteAllExpenseForCategory(categoryExpensePage.id);
                   Storage.deleteCategoryReport(categoryExpensePage.id);

                   operationresultLabel.text ="Operation Executed Successfully"
                   operationresultLabel.color = UbuntuColors.green

                   Storage.getAllCategory(); //refresh category list
                   adaptivePageLayout.removePages(categoryExpensePage);

                   deleteButton.enabled = false;

                   /* if no categoryis remains: allow at the user to import default ones*/
                   if(Storage.getAllCategoryNames().rows.length === 0 )
                      settings.defaultDataAlreadyImported = false
               }
           }
       }
   }

}
