#ifndef SCANMANAGER_H
#define SCANMANAGER_H

#include <QObject>
#include <QString>
#include <QVariant>
#include <QList>
#include <QAbstractItemModel>
#include <QModelIndex>

// 前向声明
class TreeModel;

// 扫描管理器，负责垃圾文件扫描
class ScanManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(qreal progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(int scannedFiles READ scannedFiles NOTIFY scannedFilesChanged)
    Q_PROPERTY(int scannedDirs READ scannedDirs NOTIFY scannedDirsChanged)
    Q_PROPERTY(QVariant treeResult READ treeResult NOTIFY treeResultChanged)
    Q_PROPERTY(QAbstractItemModel* treeModel READ treeModel NOTIFY treeModelChanged)

public:
    // 扫描项结构体
    struct ScanItem {
        QString name;         // 文件/目录名
        QString path;         // 绝对路径
        bool isDir;          // 是否为目录
        qint64 size;         // 文件大小（目录为0或统计值）
        bool selected;       // 选中状态
        QList<ScanItem> children; // 子节点（仅目录有，文件为空）
    };

    explicit ScanManager(QObject *parent = nullptr);

    qreal progress() const;
    int scannedFiles() const;
    int scannedDirs() const;
    QVariant treeResult() const;
    QVariant scanResult() const;
    QAbstractItemModel* treeModel() const;

    // 扫描目录常量
    static const QMap<QString, QString> kScanPaths;

public slots:
    void startScan();
    void stopScan();
    QVariant getChildren(const QString &path);

signals:
    void progressChanged();
    void scannedFilesChanged();
    void scannedDirsChanged();
    void treeResultChanged();
    void treeModelChanged();
    void scanResultChanged();
    void scanProgress(int progress, int filesCount);
    void scanFinished(const QVariant &result);

private:
    void scanDirectory(const QString &path, ScanItem &parentItem);
    QVariantMap itemToVariantMap(const ScanItem &item);
    void updateTreeModel();

    qreal m_progress;
    int m_scannedFiles;
    int m_scannedDirs;
    bool m_scanning;
    QList<ScanItem> m_scanResult;
    QVariantList m_treeResult;
    TreeModel* m_treeModel;
};

// TreeView 数据模型
class TreeModel : public QAbstractItemModel {
    Q_OBJECT

public:
    enum Roles {
        NameRole = Qt::UserRole + 1,
        PathRole,
        IsDirRole,
        SizeRole,
        SelectedRole,
        HasChildrenRole
    };

    explicit TreeModel(QObject *parent = nullptr);

    // QAbstractItemModel 接口实现
    QModelIndex index(int row, int column, const QModelIndex &parent = QModelIndex()) const override;
    QModelIndex parent(const QModelIndex &child) const override;
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    int columnCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole) override;
    Qt::ItemFlags flags(const QModelIndex &index) const override;
    QHash<int, QByteArray> roleNames() const override;

    // 自定义方法
    void setRootItems(const QList<ScanManager::ScanItem> &items);
    void loadChildren(const QModelIndex &parent, const QList<ScanManager::ScanItem> &children);
    ScanManager::ScanItem* getScanItem(const QModelIndex &index) const;

private:
    struct TreeItem {
        ScanManager::ScanItem data;
        TreeItem *parent;
        QList<TreeItem*> children;
        bool childrenLoaded;

        TreeItem(const ScanManager::ScanItem &itemData, TreeItem *parentItem = nullptr)
            : data(itemData), parent(parentItem), childrenLoaded(false) {}

        ~TreeItem() {
            qDeleteAll(children);
        }
    };

    TreeItem *m_rootItem;
    TreeItem *getTreeItem(const QModelIndex &index) const;
};

#endif // SCANMANAGER_H