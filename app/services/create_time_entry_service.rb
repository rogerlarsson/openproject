#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class CreateTimeEntryService
  include Concerns::Contracted

  self.contract = TimeEntries::CreateContract

  attr_reader :user

  def initialize(user:)
    @user = user
  end

  def call(params)
    time_entry = TimeEntry.new

    initialize_contract(time_entry)

    time_entry.attributes = params

    assign_defaults(time_entry)

    result, errors = validate_and_save(time_entry)

    ServiceResult.new(success: result,
                      errors: errors,
                      result: time_entry)
  end

  # TODO: move default value setting from time_entry.rb to here

  private

  # TODO: extract into module
  def validate_and_save(object)
    if !contract.validate
      [false, contract.errors]
    elsif !object.save
      [false, object.errors]
    else
      [object, object.errors]
    end
  end

  def assign_defaults(time_entry)
    time_entry.user ||= user
    time_entry.activity ||= TimeEntryActivity.default
    time_entry.hours = nil if time_entry.hours && time_entry.hours.zero?
    time_entry.project ||= time_entry.work_package.project if time_entry.work_package
  end

  def initialize_contract(time_entry)
    self.contract = self.class.contract.new(time_entry, user)
  end
end
