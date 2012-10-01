class Ability
  include Ability::Common
  
  include Ability::People
  include Ability::Groups
  include Ability::Events
  
  def initialize(user)
    super(user)
    
    if user.login?
      define_people_abilities
      define_groups_abilities
      define_events_abilities
    else
      # generall, a user without login permission cannot do anything
      can [:show, :modify], Person do |person|
        person.id == user.id
      end
    end

    can :modify, Person do |person|
      person.id == user.id
    end
     
     
    ### PEOPLE_FILTERS
    
    can :new, PeopleFilter do |filter|
      can_index_people?(filter.group)
    end
    
    can :create, PeopleFilter do |filter|
      layers_full.present? && layers_full.include?(filter.group.layer_group_id)
    end
    
    can :destroy, PeopleFilter do |filter|
      filter.group_id? &&
      layers_full.present? && layers_full.include?(filter.group.layer_group_id)
    end

    ### EVENTS

    can :new, Event

  end

  
  private
      
  def can_update_group?(group)
    # user has group_full for this group
    groups_group_full.include?(group.id) ||
    can_create_group?(group)
  end
    
  def can_create_group?(group)
    layers_full.present? && 
     # user has layer_full, group in same layer or below
     contains_any?(layers_full, collect_ids(group.layer_groups))
  end
  
  def can_destroy_group?(group)
    can_create_group?(group) && 
    !(groups_layer_full.include?(group.id) || layers_full.include?(group.id))
  end
  
  def can_detail_group?(group)
    user_groups.include?(group.id) ||
    (layers_read.present? && contains_any?(layers_read, collect_ids(group.layer_groups))) 
  end
  
  def can_index_people?(group)
    user.contact_data_visible? ||
    user_groups.include?(group.id) ||
    layers_read.present? && (
      layers_read.include?(group.layer_group.id) ||
      contains_any?(layers_read, collect_ids(group.layer_groups))
    )
  end
  
  def can_show_person?(person)
    # both have contact data visible
    (person.contact_data_visible? && user.contact_data_visible?) ||
    # person in same group
    contains_any?(collect_ids(person.groups), user_groups) ||
    
    (layers_read.present? && (
      # user has layer_full or layer_read, person in same layer
      contains_any?(layers_read, collect_ids(person.layer_groups)) ||

      # user has layer_full or layer_read, person below layer and visible_from_above
      contains_any?(layers_read, collect_ids(person.above_groups_visible_from))
    ))
  end
  
  def can_detail_person?(person)
    # user has group_full, person in same group
    contains_any?(groups_group_full, collect_ids(person.groups)) ||
    
    (layers_read.present? && (
      # user has layer_full or layer_read, person in same layer
      contains_any?(layers_read, collect_ids(person.layer_groups)) ||

      # user has layer_full or layer_read, person below layer and visible_from_above
      contains_any?(layers_read, collect_ids(person.above_groups_visible_from))
    ))
  end
  
  def can_modify_person?(person)
    # user has group_full, person in same group
    contains_any?(groups_group_full, collect_ids(person.groups)) ||
    
    (layers_full.present? && (
      # user has layer_full, person in same layer
      contains_any?(layers_full, collect_ids(person.layer_groups)) ||
      
      # user has layer_full, person below layer and visible_from_above
      contains_any?(layers_full, collect_ids(person.above_groups_visible_from))
    ))
  end
  
  def can_modify_role?(role)
    # user has group_full, role in same group
    groups_group_full.include?(role.group.id) ||
    
    (layers_full.present? && (
      # user has layer_full, role in same layer
      layers_full.include?(role.group.layer_group.id) ||
      
      # user has layer_full, role below layer and visible_from_above
      (role.class.visible_from_above && 
       contains_any?(layers_full, collect_ids(role.group.hierarchy)))
    ))
  end
  
  def detail_person_permissions?
    @groups_group_full.present? || @groups_layer_full.present? || @groups_layer_read.present?
  end
  
end
