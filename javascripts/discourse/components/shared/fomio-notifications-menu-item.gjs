import Component from "@glimmer/component";
import { concat } from "@ember/helper";
import { action } from "@ember/object";
import PluginOutlet from "discourse/components/plugin-outlet";
import FomioNotificationListItem from "./fomio-notification-list-item";

export default class FomioNotificationsMenuItem extends Component {
  get item() {
    return this.args.item;
  }

  get className() {
    return this.item.className;
  }

  get linkHref() {
    return this.item.linkHref;
  }

  get linkTitle() {
    return this.item.linkTitle;
  }

  get icon() {
    return this.item.icon;
  }

  get label() {
    return this.item.label;
  }

  get labelClass() {
    return this.item.labelClass;
  }

  get descriptionClass() {
    return this.item.descriptionClass;
  }

  get topicId() {
    return this.item.topicId;
  }

  get iconComponent() {
    return this.item.iconComponent;
  }

  get iconComponentArgs() {
    return this.item.iconComponentArgs;
  }

  get endComponent() {
    return this.item.endComponent;
  }

  get endOutletArgs() {
    return this.item.endOutletArgs;
  }

  @action
  onClick(event) {
    return this.item.onClick({
      event,
      closeUserMenu: this.args.closeUserMenu,
    });
  }

  <template>
    <FomioNotificationListItem
      @className={{this.className}}
      @href={{this.linkHref}}
      @title={{this.linkTitle}}
      @onClick={{this.onClick}}
      @icon={{this.icon}}
      @iconComponent={{this.iconComponent}}
      @iconComponentArgs={{this.iconComponentArgs}}
      @label={{this.label}}
      @labelClass={{this.labelClass}}
      @description={{this.item.description}}
      @descriptionClass={{this.descriptionClass}}
      @topicId={{this.topicId}}
      @endComponent={{this.endComponent}}
    />

    {{#if this.endOutletArgs}}
      <PluginOutlet @name="menu-item-end" @outletArgs={{this.endOutletArgs}} />
    {{/if}}
  </template>
}
