import Component from "@glimmer/component";

export default class FomioPhIcon extends Component {
  get href() {
    return `#${this.args.name}`;
  }

  get size() {
    return this.args.size ?? 16;
  }

  <template>
    <svg
      ...attributes
      viewBox="0 0 256 256"
      width={{this.size}}
      height={{this.size}}
      fill="currentColor"
      aria-hidden="true"
    >
      <use href={{this.href}}></use>
    </svg>
  </template>
}
