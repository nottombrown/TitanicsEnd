// This is code to send OPC packets in a manner compatible
// with the LX engine. This class defines the sending implementation
// and the engine calls it as appropriate. It may be easily
// enabled/disabled via UI, etc.

import java.net.ConnectException;
import java.net.Socket;

public static class OPCOutput extends LXOutput {
  
  static final int HEADER_LEN = 4;
  
  static final int BYTES_PER_PIXEL = 3;
  
  static final int INDEX_CHANNEL = 0;
  static final int INDEX_COMMAND = 1;
  static final int INDEX_DATA_LEN_MSB = 2;
  static final int INDEX_DATA_LEN_LSB = 3;
  static final int INDEX_DATA = 4;
  
  static final int OFFSET_R = 0;
  static final int OFFSET_G = 1;
  static final int OFFSET_B = 2;
  
  static final int COMMAND_SET_PIXEL_COLORS = 0;
  
  private final byte[] packetData;
  
  private final String host;
  private final int port;
  
  private Socket socket = null;
  private OutputStream output = null;
  
  public OPCOutput(LX lx, String host, int port) {
    super(lx);
    this.host = host;
    this.port = port;
    
    int dataLength = BYTES_PER_PIXEL*lx.total;
    this.packetData = new byte[HEADER_LEN + dataLength];
    this.packetData[INDEX_CHANNEL] = 0;
    this.packetData[INDEX_COMMAND] = COMMAND_SET_PIXEL_COLORS;
    this.packetData[INDEX_DATA_LEN_MSB] = (byte)(dataLength >>> 8);
    this.packetData[INDEX_DATA_LEN_LSB] = (byte)(dataLength & 0xFF);
    
  }
  
  private void connect() {
    if (this.socket == null) {
      try {
        this.socket = new Socket(this.host, this.port);
        this.socket.setTcpNoDelay(true);
        this.output = this.socket.getOutputStream();
        println("Connected to OPC server");
      } catch (ConnectException e) {
        dispose();
      } catch (IOException e) {
        dispose();
      }      
    }
  }
  
  private void dispose() {
    println("Disconnected from OPC server");
    this.socket = null;
    this.output = null;
  }
  
  protected void onSend(int[] colors) {
    for (int i = 0; i < colors.length; ++i) {
      int dataOffset = INDEX_DATA + i * BYTES_PER_PIXEL;
      this.packetData[dataOffset + OFFSET_R] = (byte) (0xFF & (colors[i] >> 16));
      this.packetData[dataOffset + OFFSET_G] = (byte) (0xFF & (colors[i] >> 8));
      this.packetData[dataOffset + OFFSET_B] = (byte) (0xFF & colors[i]); 
    }
    try {
      connect();
      output.write(this.packetData);
    } catch (Exception x) {
      dispose();
    }
  }
}

