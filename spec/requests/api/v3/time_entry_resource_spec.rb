#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'rack/test'

describe 'API v3 time_entry resource', type: :request do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:current_user) do
    FactoryBot.create(:user, member_in_project: project, member_through_role: role)
  end
  let(:time_entry) do
    FactoryBot.create(:time_entry, project: project, work_package: work_package, user: current_user)
  end
  let(:other_time_entry) do
    FactoryBot.create(:time_entry, project: project, work_package: work_package, user: other_user)
  end
  let(:other_user) do
    FactoryBot.create(:user, member_in_project: project, member_through_role: role)
  end
  let(:invisible_time_entry) do
    FactoryBot.create(:time_entry, project: other_project, work_package: other_work_package, user: other_user)
  end
  let(:project) { work_package.project }
  let(:work_package) { FactoryBot.create(:work_package) }
  let(:other_work_package) { FactoryBot.create(:work_package) }
  let(:other_project) { other_work_package.project }
  let(:role) { FactoryBot.create(:role, permissions: permissions) }
  let(:permissions) { %i(view_time_entries view_work_packages) }
  let(:custom_field) { FactoryBot.create(:time_entry_custom_field) }
  let(:custom_value) do
    CustomValue.create(custom_field: custom_field,
                       value: '1234',
                       customized: time_entry)
  end
  let(:activity) do
    FactoryBot.create(:time_entry_activity)
  end

  subject(:response) { last_response }

  before do
    login_as(current_user)

    OpenProject::Cache.clear
  end

  describe 'GET api/v3/time_entries' do
    let(:path) { api_v3_paths.time_entries }

    context 'without params' do
      before do
        time_entry
        invisible_time_entry
        custom_value

        get path
      end

      it 'responds 200 OK' do
        expect(subject.status).to eq(200)
      end

      it 'returns a collection of time entries containing only the visible time entries' do
        expect(subject.body)
          .to be_json_eql('Collection'.to_json)
          .at_path('_type')

        expect(subject.body)
          .to be_json_eql('1')
          .at_path('total')

        expect(subject.body)
          .to be_json_eql(time_entry.id.to_json)
          .at_path('_embedded/elements/0/id')

        expect(subject.body)
          .to be_json_eql(custom_value.value.to_json)
          .at_path("_embedded/elements/0/customField#{custom_field.id}/raw")
      end
    end

    context 'with pageSize, offset and sortBy' do
      let(:path) { "#{api_v3_paths.time_entries}?pageSize=1&offset=2&sortBy=#{[%i(id asc)].to_json}" }

      before do
        time_entry
        other_time_entry
        invisible_time_entry

        get path
      end

      it 'returns a slice of the visible time entries' do
        expect(subject.body)
          .to be_json_eql('Collection'.to_json)
          .at_path('_type')

        expect(subject.body)
          .to be_json_eql('2')
          .at_path('total')

        expect(subject.body)
          .to be_json_eql('1')
          .at_path('count')

        expect(subject.body)
          .to be_json_eql(other_time_entry.id.to_json)
          .at_path('_embedded/elements/0/id')
      end
    end

    context 'filtering by user' do
      let(:invisible_time_entry) do
        FactoryBot.create(:time_entry, project: other_project, work_package: other_work_package, user: other_user)
      end

      before do
        time_entry
        other_time_entry
        invisible_time_entry

        get path
      end

      let(:path) do
        filter = [{ 'user' => {
          'operator' => '=',
          'values' => [other_user.id]
        } }]

        "#{api_v3_paths.time_entries}?#{{ filters: filter.to_json }.to_query}"
      end

      it 'contains only the filtered time entries in the response' do
        expect(subject.body)
          .to be_json_eql('1')
          .at_path('total')

        expect(subject.body)
          .to be_json_eql(other_time_entry.id.to_json)
          .at_path('_embedded/elements/0/id')
      end
    end

    context 'filtering by work package' do
      let(:unwanted_work_package) do
        FactoryBot.create(:work_package, project: project, type: project.types.first)
      end

      let(:other_time_entry) do
        FactoryBot.create(:time_entry, project: project, work_package: unwanted_work_package, user: current_user)
      end

      let(:path) do
        filter = [{ 'work_package' => {
          'operator' => '=',
          'values' => [work_package.id]
        } }]

        "#{api_v3_paths.time_entries}?#{{ filters: filter.to_json }.to_query}"
      end

      before do
        time_entry
        other_time_entry
        invisible_time_entry

        get path
      end

      it 'contains only the filtered time entries in the response' do
        expect(subject.body)
          .to be_json_eql('1')
          .at_path('total')

        expect(subject.body)
          .to be_json_eql(time_entry.id.to_json)
          .at_path('_embedded/elements/0/id')
      end
    end

    context 'filtering by project' do
      let(:other_time_entry) do
        FactoryBot.create(:time_entry, project: other_project, work_package: other_work_package, user: current_user)
      end

      before do
        FactoryBot.create(:member,
                          roles: [role],
                          project: other_project,
                          user: current_user)

        time_entry
        other_time_entry

        get path
      end

      let(:path) do
        filter = [{ 'project' => {
          'operator' => '=',
          'values' => [other_project.id]
        } }]

        "#{api_v3_paths.time_entries}?#{{ filters: filter.to_json }.to_query}"
      end

      it 'contains only the filtered time entries in the response' do
        expect(subject.body)
          .to be_json_eql('1')
          .at_path('total')

        expect(subject.body)
          .to be_json_eql(other_time_entry.id.to_json)
          .at_path('_embedded/elements/0/id')
      end
    end

    context 'invalid filter' do
      let(:path) do
        filter = [{ 'bogus' => {
          'operator' => '=',
          'values' => ['1']
        } }]

        "#{api_v3_paths.time_entries}?#{{ filters: filter.to_json }.to_query}"
      end

      before do
        time_entry

        get path
      end

      it 'returns an error' do
        expect(subject.status).to eq(400)

        expect(subject.body)
          .to be_json_eql('urn:openproject-org:api:v3:errors:InvalidQuery'.to_json)
          .at_path('errorIdentifier')
      end
    end
  end

  describe 'GET /api/v3/time_entries/:id' do
    let(:path) { api_v3_paths.time_entry(time_entry.id) }

    before do
      time_entry
      custom_value

      get path
    end

    it 'returns 200 OK' do
      expect(subject.status)
        .to eql(200)
    end

    it 'returns the time entry' do
      expect(subject.body)
        .to be_json_eql('TimeEntry'.to_json)
        .at_path('_type')

      expect(subject.body)
        .to be_json_eql(time_entry.id.to_json)
        .at_path('id')

      expect(subject.body)
        .to be_json_eql(custom_value.value.to_json)
        .at_path("customField#{custom_field.id}/raw")
    end

    context 'when lacking permissions' do
      let(:permissions) { [] }

      it 'returns 404 NOT FOUND' do
        expect(subject.status)
          .to eql(404)
      end
    end
  end

  describe 'POST api/v3/time_entries' do
    let(:permissions) { %i(view_time_entries log_time view_work_packages) }
    let(:path) { api_v3_paths.time_entries }
    let(:params) do
      {
        "_links": {
          "project": {
            "href": api_v3_paths.project(project.id)
          },
          "activity": {
            "href": api_v3_paths.time_entries_activity(activity.id)
          },
          "workPackage": {
            "href": api_v3_paths.work_package(work_package.id)
          }
        },
        "hours": 'PT5H',
        "comment": "some comment",
        "spentOn": "2017-07-28"
      }
    end

    before do
      work_package

      post path, params.to_json, 'CONTENT_TYPE' => 'application/json'
    end

    it 'responds 201 CREATED' do
      expect(subject.status).to eq(201)
    end

    it 'creates another time entry with the provided values' do
      expect(TimeEntry.count)
        .to eql 1

      new_entry = TimeEntry.first

      expect(new_entry.user)
        .to eql current_user

      expect(new_entry.project)
        .to eql project

      expect(new_entry.activity)
        .to eql activity

      expect(new_entry.work_package)
        .to eql work_package

      expect(new_entry.hours)
        .to eql 5.0

      expect(new_entry.comments)
        .to eql "some comment"

      expect(new_entry.spent_on)
        .to eql Date.parse("2017-07-28")
    end

    context 'when lacking permissions' do
      let(:permissions) { %i(view_time_entries view_work_packages) }

      it 'returns 403' do
        expect(subject.status)
          .to eql(403)
      end
    end
  end
end
