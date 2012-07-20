# Copyright (C) 2010-2012, InSTEDD
#
# This file is part of Verboice.
#
# Verboice is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Verboice is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Verboice.  If not, see <http://www.gnu.org/licenses/>.

module Parsers
  module UserFlowNode
    class Record < UserCommand
      attr_reader :id, :name, :call_flow
      attr_accessor :next

      def initialize call_flow, params
        @id = params['id']
        @name = params['name'] || ''
        @explanation_message = Message.for call_flow, self, :explanation, params['explanation_message']
        @confirmation_message = Message.for call_flow, self, :confirmation, params['confirmation_message']
        @timeout = params['timeout']
        @stop_key = params['stop_key']
        @call_flow = call_flow
        @next = params['next']
        @root_index = params['root']
      end

      def is_root?
        @root_index.present?
      end

      def root_index
        @root_index
      end

      def equivalent_flow
        Compiler.parse do |compiler|
          compiler.Label @id
          compiler.Assign "current_step", @id
          compiler.AssignValue "current_step_name", "#{@name}"
          compiler.Trace context_for %("Record message. Download link: " + record_url(#{@id}))
          compiler.append @explanation_message.equivalent_flow
          compiler.Record @id, @name, {:stop_keys => @stop_key, :timeout => @timeout}
          compiler.append @confirmation_message.equivalent_flow
          compiler.append @next.equivalent_flow if @next
        end
      end
    end
  end
end
