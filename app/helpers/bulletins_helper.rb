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

  # The import source marker is retained in the database for safe idempotent re-import,
  # but must not appear in public listings or gallery descriptions.
  def public_bulletin_description(description)
    description.to_s.sub(/\n\nДемонстрационная запись из учебного проекта\. \[CLASSIFIEDS_DEMO_SOURCE_ID:\d+\]\z/, '')
  end

  def bulletin_state_options
    Bulletin.aasm.states.map { |state| [ bulletin_state_label(state.name), state.name.to_s ] }
  end
end
