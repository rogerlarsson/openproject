// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {Injectable, Injector} from '@angular/core';
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {AbstractFieldService, IFieldType} from "core-app/modules/fields/field.service";
import {IFieldSchema} from "core-app/modules/fields/field.base";
import {EditField} from "core-app/modules/fields/edit/edit.field.module";
import {DisplayField} from "core-app/modules/fields/display/display-field.module";
import {DisplayFieldContext, IDisplayFieldType} from "core-app/modules/fields/display/display-field.service";

export interface IEditFieldType extends IFieldType<EditField> {
  new(resource:WorkPackageResource, attributeType:string, schema:IFieldSchema):EditField;
}

@Injectable()
export class EditFieldService extends AbstractFieldService<EditField, IEditFieldType> {

  constructor(injector:Injector) {
    super(injector);
  }

  /**
   * Create an instance of the field type given the required arguments
   * with either in descending order:
   *
   *  1. The registered field name (most specific)
   *  2. The registered field for the schema attribute type
   *  3. The default field type
   *
   * @param resource
   * @param {string} fieldName
   * @param {IFieldSchema} schema
   * @returns {T}
   */
  public getField(resource:any, fieldName:string, schema:IFieldSchema):EditField {
    let type = this.fieldType(fieldName) || this.fieldType(schema.type) || this.defaultFieldType;
    let fieldClass:IEditFieldType = this.classes[type];

    return new fieldClass(resource, fieldName, schema);
  }
}
