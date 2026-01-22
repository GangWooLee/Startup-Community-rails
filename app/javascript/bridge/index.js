/**
 * Bridge 모듈 진입점
 *
 * 웹-네이티브 통신을 위한 모든 기능을 내보냄
 *
 * 사용법:
 *   import { BridgeNative } from "bridge"
 *   // 또는
 *   import BridgeNative from "bridge/native_messenger"
 */
import BridgeNative from "./native_messenger"

export { BridgeNative }
export default BridgeNative
