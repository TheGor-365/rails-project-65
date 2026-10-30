# frozen_string_literal: true

module BulletinsHelper
  STATE_LABELS = {
    'draft' => 'Черновик',
    'under_moderation' => 'На модерации',
    'published' => 'Опубликовано',
    'rejected' => 'Отклонено',
    'archived' => 'В архиве'
  }.freeze

  def bulletin_state_label(state)
    STATE_LABELS.fetch(state.to_s, state.to_s.humanize)
  end

  def bulletin_state_options
    Bulletin.aasm.states.map { |state| [ bulletin_state_label(state.name), state.name.to_s ] }
  end
end
