import sys
import ast
import numpy as np
import matplotlib.pyplot as plt

def parse_haskell_output(filename):
    data = {}
    current_key = None
    with open(filename, 'r') as f:
        lines = f.readlines()
        
    in_export = False
    for line in lines:
        line = line.strip()
        if line == "--- HASKELL_EXPORT_START ---":
            in_export = True
            continue
        if line == "--- HASKELL_EXPORT_END ---":
            in_export = False
            continue
        if in_export:
            if line in ["TRAIN_DATA", "TRAIN_LABELS", "TRAIN_PROBS", "TEST_DATA", "TEST_LABELS", "TEST_PROBS"]:
                current_key = line
            else:
                data[current_key] = ast.literal_eval(line)
    
    return data

def plot_nesycat(data, out_filename="nesycat_binary_testing.png"):
    train_data = np.array(data["TRAIN_DATA"])
    train_labels = np.array(data["TRAIN_LABELS"]).squeeze() > 0.5
    train_probs = np.array(data["TRAIN_PROBS"]).squeeze()
    
    test_data = np.array(data["TEST_DATA"])
    test_labels = np.array(data["TEST_LABELS"]).squeeze() > 0.5
    test_probs = np.array(data["TEST_PROBS"]).squeeze()
    
    # Combine for groundtruth
    dataset = np.vstack((train_data, test_data))
    labels = np.concatenate((train_labels, test_labels))
    
    fig = plt.figure(figsize=(9, 11))

    plt.subplots_adjust(wspace=0.2,hspace=0.3)
    ax = plt.subplot2grid((3,8),(0,2),colspan=4)
    ax.set_title("NeSyCat (HaskTorch) Groundtruth")
    ax.scatter(dataset[labels][:,0],dataset[labels][:,1],label='A', c='tab:blue')
    ax.scatter(dataset[np.logical_not(labels)][:,0],dataset[np.logical_not(labels)][:,1],label='~A', c='tab:orange')
    ax.legend()
    
    fig.add_subplot(3, 2, 3)
    plt.title("A(x) - training data")
    plt.scatter(train_data[:,0], train_data[:,1], c=train_probs, vmin=0, vmax=1, cmap='viridis')
    plt.colorbar()

    fig.add_subplot(3, 2, 4)
    plt.title("~A(x) - training data")
    plt.scatter(train_data[:,0], train_data[:,1], c=1-train_probs, vmin=0, vmax=1, cmap='viridis')
    plt.colorbar()

    fig.add_subplot(3, 2, 5)
    plt.title("A(x) - test data")
    plt.scatter(test_data[:,0], test_data[:,1], c=test_probs, vmin=0, vmax=1, cmap='viridis')
    plt.colorbar()

    fig.add_subplot(3, 2, 6)
    plt.title("~A(x) - test data")
    plt.scatter(test_data[:,0], test_data[:,1], c=1-test_probs, vmin=0, vmax=1, cmap='viridis')
    plt.colorbar()

    plt.savefig(out_filename, bbox_inches='tight')
    plt.close()

if __name__ == "__main__":
    if len(sys.argv) > 1:
        data = parse_haskell_output(sys.argv[1])
        plot_nesycat(data, "nesycat_binary_testing.png")
        # Copy to artifacts directory
        import shutil
        import time
        import os
        ts = int(time.time() * 1000)
        dest = f"/Users/cherryfunk/.gemini/antigravity/brain/bcd893ac-57a6-4247-90f8-502e676b1ea8/media_plot_{ts}.png"
        shutil.copy("nesycat_binary_testing.png", dest)
        try:
            with open("media_path.txt", "w") as f:
                f.write(dest)
        except Exception as e:
            print(f"Error writing artifact path: {e}")
            sys.exit(1)
        print(f"Plot saved to nesycat_binary_testing.png and artifact {dest}")
